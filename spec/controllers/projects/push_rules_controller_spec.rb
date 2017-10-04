require 'spec_helper'

describe Projects::PushRulesController do
  let(:project) { create(:project, push_rule: create(:push_rule, prevent_secrets: false)) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)

    sign_in(user)
  end

  describe '#update' do
    def do_update
      patch :update, namespace_id: project.namespace, project_id: project, id: 1, push_rule: { prevent_secrets: true }
    end

    it 'updates the push rule' do
      do_update

      expect(response).to have_http_status(302)
      expect(project.push_rule(true).prevent_secrets).to be_truthy
    end

    context 'push rules unlicensed' do
      before do
        stub_licensed_features(push_rules: false)
      end

      it 'returns 404' do
        do_update

        expect(response).to have_http_status(404)
      end
    end

    context 'Updating reject unsigned commit rule' do
      context 'as an admin' do
        let(:user) { create(:admin) }

        it 'updates the setting' do
          patch :update, namespace_id: project.namespace, project_id: project, id: 1, push_rule: { reject_unsigned_commits: true }

          expect(project.push_rule(true).reject_unsigned_commits).to be_truthy
        end
      end

      context 'as a master user' do
        before do
          project.add_master(user)
        end

        context 'when global setting is disabled' do
          it 'updates the setting' do
            patch :update, namespace_id: project.namespace, project_id: project, id: 1, push_rule: { reject_unsigned_commits: true }

            expect(project.push_rule(true).reject_unsigned_commits).to be_truthy
          end
        end

        context 'when global setting is enabled' do
          before do
            create(:push_rule_sample, reject_unsigned_commits: true)
          end

          it 'does not update the setting' do
            patch :update, namespace_id: project.namespace, project_id: project, id: 1, push_rule: { reject_unsigned_commits: false }

            expect(project.push_rule(true).reject_unsigned_commits).to be_truthy
          end
        end
      end

      context 'as a developer user' do
        before do
          project.add_developer(user)
        end

        it 'does not update the setting' do
          patch :update, namespace_id: project.namespace, project_id: project, id: 1, push_rule: { reject_unsigned_commits: true }

          expect(project.push_rule(true).reject_unsigned_commits).to be_falsy
        end
      end
    end
  end
end
