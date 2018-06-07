require "spec_helper"

describe API::MergeRequests do
  include ProjectForksHelper

  let(:base_time)   { Time.now }
  let(:user)        { create(:user) }
  let!(:project)    { create(:project, :public, :repository, creator: user, namespace: user.namespace, only_allow_merge_if_pipeline_succeeds: false) }
  let(:milestone)   { create(:milestone, title: '1.0.0', project: project) }
  let(:milestone1)   { create(:milestone, title: '0.9', project: project) }
  let!(:merge_request) { create(:merge_request, :simple, milestone: milestone1, author: user, assignee: user, source_project: project, target_project: project, title: "Test", created_at: base_time) }
  let!(:label) do
    create(:label, title: 'label', color: '#FFAABB', project: project)
  end
  let!(:label2) { create(:label, title: 'a-test', color: '#FFFFFF', project: project) }

  before do
    project.add_reporter(user)
  end

  describe "POST /projects/:id/merge_requests" do
    def create_merge_request(args)
      defaults = {
          title: 'Test merge_request',
          source_branch: 'feature_conflict',
          target_branch: 'master',
          author: user,
          labels: 'label, label2',
          milestone_id: milestone.id
      }
      defaults = defaults.merge(args)
      post api("/projects/#{project.id}/merge_requests", user), defaults
    end
    context 'between branches projects' do
      it "returns merge_request" do
        create_merge_request(squash: true)

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['title']).to eq('Test merge_request')
        expect(json_response['labels']).to eq(%w(label label2))
        expect(json_response['milestone']['id']).to eq(milestone.id)
        expect(json_response['squash']).to be_truthy
        expect(json_response['force_remove_source_branch']).to be_falsy
      end

      context 'the approvals_before_merge param' do
        context 'when the target project has disable_overriding_approvers_per_merge_request set to true' do
          before do
            project.update_attributes(disable_overriding_approvers_per_merge_request: true)
            create_merge_request(approvals_before_merge: 1)
          end

          it 'does not update approvals_before_merge' do
            expect(json_response['approvals_before_merge']).to eq(nil)
          end
        end

        context 'when the target project has approvals_before_merge set to zero' do
          before do
            project.update_attributes(approvals_before_merge: 0)
            create_merge_request(approvals_before_merge: 1)
          end

          it 'returns a 201' do
            expect(response).to have_gitlab_http_status(201)
          end

          it 'does not include an error in the response' do
            expect(json_response['message']).to eq(nil)
          end
        end

        context 'when the target project has a non-zero approvals_before_merge' do
          context 'when the approvals_before_merge param is less than or equal to the value in the target project' do
            before do
              project.update_attributes(approvals_before_merge: 2)
              create_merge_request(approvals_before_merge: 1)
            end

            it 'returns a 400' do
              expect(response).to have_gitlab_http_status(400)
            end

            it 'includes the error in the response' do
              expect(json_response['message']['validate_approvals_before_merge']).not_to be_empty
            end
          end

          context 'when the approvals_before_merge param is greater than the value in the target project' do
            before do
              project.update_attributes(approvals_before_merge: 1)
              create_merge_request(approvals_before_merge: 2)
            end

            it 'returns a created status' do
              expect(response).to have_gitlab_http_status(201)
            end

            it 'sets approvals_before_merge of the newly-created MR' do
              expect(json_response['approvals_before_merge']).to eq(2)
            end
          end
        end
      end
    end
  end
end
