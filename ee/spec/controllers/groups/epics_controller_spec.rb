require 'spec_helper'

describe Groups::EpicsController do
  let(:group) { create(:group, :private) }
  let(:epic) { create(:epic, group: group) }
  let(:user)  { create(:user) }
  let(:label) { create(:group_label, group: group, title: 'Bug') }

  before do
    sign_in(user)
  end

  context 'when epics feature is disabled' do
    shared_examples '404 status' do
      it 'returns 404 status' do
        subject

        expect(response).to have_gitlab_http_status(404)
      end
    end

    describe 'GET #index' do
      subject { get :index, group_id: group }

      it_behaves_like '404 status'
    end

    describe 'GET #show' do
      subject { get :show, group_id: group, id: epic.to_param }

      it_behaves_like '404 status'
    end

    describe 'PUT #update' do
      subject { put :update, group_id: group, id: epic.to_param }

      it_behaves_like '404 status'
    end
  end

  context 'when epics feature is enabled' do
    before do
      stub_licensed_features(epics: true)
    end

    describe "GET #index" do
      let!(:epic_list) { create_list(:epic, 2, group: group) }

      before do
        sign_in(user)
        group.add_developer(user)
      end

      it "returns index" do
        get :index, group_id: group

        expect(response).to have_gitlab_http_status(200)
      end

      it 'stores sorting param in a cookie' do
        get :index, group_id: group, sort: 'start_date_asc'

        expect(cookies['epic_sort']).to eq('start_date_asc')
        expect(response).to have_gitlab_http_status(200)
      end

      context 'with page param' do
        let(:last_page) { group.epics.page.total_pages }

        before do
          allow(Kaminari.config).to receive(:default_per_page).and_return(1)
        end

        it 'redirects to last_page if page number is larger than number of pages' do
          get :index, group_id: group, page: (last_page + 1).to_param

          expect(response).to redirect_to(group_epics_path(page: last_page, state: controller.params[:state], scope: controller.params[:scope]))
        end

        it 'renders the specified page' do
          get :index, group_id: group, page: last_page.to_param

          expect(assigns(:epics).current_page).to eq(last_page)
          expect(response).to have_gitlab_http_status(200)
        end

        it_behaves_like 'disabled when using an external authorization service' do
          subject { get :index, group_id: group }
        end
      end

      context 'when format is JSON' do
        before do
          allow(Kaminari.config).to receive(:default_per_page).and_return(1)
        end

        def list_epics
          get :index, group_id: group, format: :json
        end

        it 'returns a list of epics' do
          list_epics

          expect(json_response).to be_an Array
        end

        it 'does not use pagination' do
          list_epics

          expect(json_response.size).to eq(2)
        end

        it 'returns correct epic attributes' do
          list_epics
          item = json_response.first
          epic = Epic.find(item['id'])

          expect(item['group_id']).to eq(group.id)
          expect(item['start_date']).to eq(epic.start_date)
          expect(item['end_date']).to eq(epic.end_date)
          expect(item['web_url']).to eq(group_epic_path(group, epic))
        end

        context 'using label_name filter' do
          let(:label) { create(:label) }
          let!(:labeled_epic) { create(:labeled_epic, group: group, labels: [label]) }

          it 'returns all epics with given label' do
            get :index, group_id: group, label_name: label.title, format: :json

            expect(json_response.size).to eq(1)
            expect(json_response.first['id']).to eq(labeled_epic.id)
          end
        end
      end
    end

    describe 'GET #show' do
      def show_epic(format = :html)
        get :show, group_id: group, id: epic.to_param, format: format
      end

      context 'when format is HTML' do
        it 'renders template' do
          group.add_developer(user)
          show_epic

          expect(response.content_type).to eq 'text/html'
          expect(response).to render_template 'groups/epics/show'
        end

        context 'with unauthorized user' do
          it 'returns a not found 404 response' do
            show_epic

            expect(response).to have_http_status(404)
            expect(response.content_type).to eq 'text/html'
          end
        end

        it_behaves_like 'disabled when using an external authorization service' do
          subject { show_epic }

          before do
            group.add_developer(user)
          end
        end
      end

      context 'when format is JSON' do
        it 'returns epic' do
          group.add_developer(user)
          show_epic(:json)

          expect(response).to have_http_status(200)
          expect(response).to match_response_schema('entities/epic', dir: 'ee')
        end

        context 'with unauthorized user' do
          it 'returns a not found 404 response' do
            show_epic(:json)

            expect(response).to have_http_status(404)
            expect(response.content_type).to eq 'application/json'
          end
        end
      end
    end

    describe 'PUT #update' do
      let(:date) { Date.new(2002, 1, 1)}

      before do
        group.add_developer(user)
        put :update, group_id: group, id: epic.to_param, epic: { title: 'New title', label_ids: [label.id], start_date_fixed: '2002-01-01', start_date_is_fixed: true }, format: :json
      end

      it 'returns status 200' do
        expect(response.status).to eq(200)
      end

      it 'updates the epic correctly' do
        epic.reload

        expect(epic.title).to eq('New title')
        expect(epic.labels).to eq([label])
        expect(epic.start_date_fixed).to eq(date)
        expect(epic.start_date).to eq(date)
        expect(epic.start_date_is_fixed).to eq(true)
      end
    end

    describe 'GET #realtime_changes' do
      subject { get :realtime_changes, group_id: group, id: epic.to_param }

      it 'returns epic' do
        group.add_developer(user)
        subject

        expect(response.content_type).to eq 'application/json'
        expect(JSON.parse(response.body)).to include('title_text', 'title', 'description', 'description_text')
      end

      context 'with unauthorized user' do
        it 'returns a not found 404 response' do
          subject

          expect(response).to have_http_status(404)
        end
      end

      it_behaves_like 'disabled when using an external authorization service' do
        before do
          group.add_developer(user)
        end
      end
    end

    describe '#create' do
      subject do
        post :create, group_id: group, epic: { title: 'new epic', description: 'some descripition', label_ids: [label.id] }
      end

      context 'when user has permissions to create an epic' do
        before do
          group.add_developer(user)
        end

        context 'when all required parameters are passed' do
          it 'returns 200 response' do
            subject

            expect(response).to have_http_status(200)
          end

          it 'creates a new epic' do
            expect { subject }.to change { Epic.count }.from(0).to(1)
          end

          it 'assigns labels to the new epic' do
            expect { subject }.to change { LabelLink.count }.from(0).to(1)
          end

          it 'returns the correct json' do
            subject

            expect(JSON.parse(response.body)).to eq({ 'web_url' => group_epic_path(group, Epic.last) })
          end

          it_behaves_like 'disabled when using an external authorization service'
        end

        context 'when required parameter is missing' do
          before do
            post :create, group_id: group, epic: { description: 'some descripition' }
          end

          it 'returns 422 response' do
            expect(response).to have_gitlab_http_status(422)
          end

          it 'does not create a new epic' do
            expect(Epic.count).to eq(0)
          end
        end
      end

      context 'with unauthorized user' do
        it 'returns a not found 404 response' do
          group.add_guest(user)
          subject

          expect(response).to have_http_status(404)
        end
      end
    end

    describe "DELETE #destroy" do
      before do
        sign_in(user)
      end

      it "rejects a developer to destroy an epic" do
        group.add_developer(user)
        delete :destroy, group_id: group, id: epic.to_param

        expect(response).to have_gitlab_http_status(404)
      end

      it "deletes the epic" do
        group.add_owner(user)
        delete :destroy, group_id: group, id: epic.to_param

        expect(response).to have_gitlab_http_status(302)
        expect(controller).to set_flash[:notice].to(/The epic was successfully deleted\./)
      end
    end
  end
end
