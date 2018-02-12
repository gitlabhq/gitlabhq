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

      expect(response).to have_gitlab_http_status(302)
      expect(project.push_rule(true).prevent_secrets).to be_truthy
    end

    context 'push rules unlicensed' do
      before do
        stub_licensed_features(push_rules: false)
      end

      it 'returns 404' do
        do_update

        expect(response).to have_gitlab_http_status(404)
      end
    end

    PushRule::SETTINGS_WITH_GLOBAL_DEFAULT.each do |rule_attr|
      context "Updating #{rule_attr} rule" do
        context 'as an admin' do
          let(:user) { create(:admin) }

          it 'updates the setting' do
            patch :update, namespace_id: project.namespace, project_id: project, id: 1, push_rule: { rule_attr => true }

            expect(project.push_rule(true).public_send(rule_attr)).to be_truthy
          end
        end

        context 'as a master user' do
          before do
            project.add_master(user)
          end

          context 'when global setting is disabled' do
            it 'updates the setting' do
              patch :update, namespace_id: project.namespace, project_id: project, id: 1, push_rule: { rule_attr => true }

              expect(project.push_rule(true).public_send(rule_attr)).to be_truthy
            end
          end

          context 'when global setting is enabled' do
            before do
              create(:push_rule_sample, rule_attr => true)
            end

            it 'does not update the setting' do
              patch :update, namespace_id: project.namespace, project_id: project, id: 1, push_rule: { rule_attr => false }

              expect(project.push_rule(true).public_send(rule_attr)).to be_truthy
            end
          end
        end

        context 'as a developer user' do
          before do
            project.add_developer(user)
          end

          it 'does not update the setting' do
            patch :update, namespace_id: project.namespace, project_id: project, id: 1, push_rule: { rule_attr => true }

            expect(project.push_rule(true).public_send(rule_attr)).to be_falsy
          end
        end
      end
    end
  end
end
