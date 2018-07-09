require 'spec_helper'

describe API::Namespaces do
  let(:admin) { create(:admin) }
  let(:user) { create(:user) }
  let!(:group1) { create(:group) }
  let!(:group2) { create(:group, :nested) }

  describe "GET /namespaces" do
    context "when authenticated as admin" do
      it "returns correct attributes" do
        get api("/namespaces", admin)

        group_kind_json_response = json_response.find { |resource| resource['kind'] == 'group' }
        user_kind_json_response = json_response.find { |resource| resource['kind'] == 'user' }

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(group_kind_json_response.keys).to contain_exactly('id', 'kind', 'name', 'path', 'full_path',
                                                                 'parent_id', 'members_count_with_descendants',
                                                                 'plan', 'shared_runners_minutes_limit',
                                                                 'trial_ends_on')

        expect(user_kind_json_response.keys).to contain_exactly('id', 'kind', 'name', 'path', 'full_path',
                                                                'parent_id', 'plan', 'shared_runners_minutes_limit',
                                                                'trial_ends_on')
      end
    end

    context "when authenticated as a regular user" do
      it "returns correct attributes when user can admin group" do
        group1.add_owner(user)

        get api("/namespaces", user)

        owned_group_response = json_response.find { |resource| resource['id'] == group1.id }

        expect(owned_group_response.keys).to contain_exactly('id', 'kind', 'name', 'path', 'full_path',
                                                             'plan', 'parent_id', 'members_count_with_descendants',
                                                             'trial_ends_on')
      end

      it "returns correct attributes when user cannot admin group" do
        group1.add_guest(user)

        get api("/namespaces", user)

        guest_group_response = json_response.find { |resource| resource['id'] == group1.id }

        expect(guest_group_response.keys).to contain_exactly('id', 'kind', 'name', 'path', 'full_path', 'parent_id',
                                                             'trial_ends_on')
      end
    end
  end

  describe 'PUT /namespaces/:id' do
    before do
      create(:silver_plan)
    end

    context 'when authenticated as admin' do
      it 'updates namespace using full_path' do
        put api("/namespaces/#{group1.full_path}", admin), plan: 'silver', shared_runners_minutes_limit: 9001

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['plan']).to eq('silver')
        expect(json_response['shared_runners_minutes_limit']).to eq(9001)
      end

      it 'updates namespace using id' do
        put api("/namespaces/#{group1.id}", admin), plan: 'silver', shared_runners_minutes_limit: 9001

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['plan']).to eq('silver')
        expect(json_response['shared_runners_minutes_limit']).to eq(9001)
      end

      context 'setting the trial expiration date' do
        context 'when the attr has a future date' do
          it 'updates the trial expiration date' do
            date = 30.days.from_now.to_date

            put api("/namespaces/#{group1.id}", admin), trial_ends_on: date

            expect(response).to have_gitlab_http_status(200)
            expect(json_response['trial_ends_on']).to eq(date.to_s)
          end
        end

        context 'when the attr has an old date' do
          it 'returns 400' do
            put api("/namespaces/#{group1.id}", admin), trial_ends_on: 2.days.ago.to_date

            expect(response).to have_gitlab_http_status(400)
            expect(json_response['trial_ends_on']).to eq(nil)
          end
        end
      end
    end

    context 'when not authenticated as admin' do
      it 'retuns 403' do
        put api("/namespaces/#{group1.id}", user), plan: 'silver'

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'when namespace not found' do
      it 'returns 404' do
        put api("/namespaces/12345", admin), plan: 'silver'

        expect(response).to have_gitlab_http_status(404)
        expect(json_response).to eq('message' => '404 Namespace Not Found')
      end
    end

    context 'when invalid params' do
      it 'returns validation error' do
        put api("/namespaces/#{group1.id}", admin), plan: 'unknown'

        expect(response).to have_gitlab_http_status(400)
        expect(json_response['message']).to eq('plan' => ['is not included in the list'])
      end
    end
  end
end
