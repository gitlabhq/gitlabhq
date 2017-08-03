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
  end
end
