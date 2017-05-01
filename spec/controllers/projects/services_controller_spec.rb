require 'spec_helper'

describe Projects::ServicesController do
  let(:project) { create(:project, :repository) }
  let(:user)    { create(:user) }
  let(:service) { create(:service, project: project) }

  before do
    sign_in(user)
    project.team << [user, :master]

    controller.instance_variable_set(:@project, project)
    controller.instance_variable_set(:@service, service)
  end

  shared_examples_for 'services controller' do |referrer|
    before do
      request.env["HTTP_REFERER"] = referrer
    end

    describe "#test" do
      context 'when can_test? returns false' do
        it 'renders 404' do
          allow_any_instance_of(Service).to receive(:can_test?).and_return(false)

          get :test, namespace_id: project.namespace.id, project_id: project.id, id: service.id, format: :html

          expect(response).to have_http_status(404)
        end
      end

      context 'success' do
        context 'with empty project' do
          let(:project) { create(:empty_project) }

          context 'with chat notification service' do
            let(:service) { project.create_microsoft_teams_service(webhook: 'http://webhook.com') }

            it 'redirects and show success message' do
              allow_any_instance_of(MicrosoftTeams::Notifier).to receive(:ping).and_return(true)

              get :test, namespace_id: project.namespace.id, project_id: project.id, id: service.id, format: :html

              expect(response).to redirect_to(root_path)
              expect(flash[:notice]).to eq('We sent a request to the provided URL')
            end
          end

          it 'redirects and show success message' do
            expect(service).to receive(:test).and_return(success: true, result: 'done')

            get :test, namespace_id: project.namespace.id, project_id: project.id, id: service.id, format: :html

            expect(response).to redirect_to(root_path)
            expect(flash[:notice]).to eq('We sent a request to the provided URL')
          end
        end

        it "redirects and show success message" do
          expect(service).to receive(:test).and_return(success: true, result: 'done')

          get :test, namespace_id: project.namespace.id, project_id: project.id, id: service.id, format: :html

          expect(response).to redirect_to(root_path)
          expect(flash[:notice]).to eq('We sent a request to the provided URL')
        end
      end

      context 'failure' do
        it "redirects and show failure message" do
          expect(service).to receive(:test).and_return(success: false, result: 'Bad test')

          get :test, namespace_id: project.namespace.id, project_id: project.id, id: service.id, format: :html

          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to eq('We tried to send a request to the provided URL but an error occurred: Bad test')
        end
      end
    end
  end

  describe 'referrer defined' do
    it_should_behave_like 'services controller' do
      let!(:referrer) { "/" }
    end
  end

  describe 'referrer undefined' do
    it_should_behave_like 'services controller' do
      let!(:referrer) { nil }
    end
  end

  describe 'PUT #update' do
    context 'on successful update' do
      it 'sets the flash' do
        expect(service).to receive(:to_param).and_return('hipchat')
        expect(service).to receive(:event_names).and_return(HipchatService.event_names)

        put :update,
          namespace_id: project.namespace.id,
          project_id: project.id,
          id: service.id,
          service: { active: false }

        expect(flash[:notice]).to eq 'Successfully updated.'
      end
    end
  end
end
