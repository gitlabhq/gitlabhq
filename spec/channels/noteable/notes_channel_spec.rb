# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Noteable::NotesChannel, feature_category: :team_planning do
  let_it_be(:project) { create(:project, :repository, :private) }
  let_it_be(:developer) { create(:user).tap { |u| project.add_developer(u) } }

  describe '#subscribed' do
    let(:subscribe_params) do
      {
        project_id: noteable.project_id,
        noteable_type: noteable.class.underscore,
        noteable_id: noteable.id
      }
    end

    before do
      stub_action_cable_connection current_user: developer
    end

    it 'rejects the subscription when noteable params are missing' do
      subscribe(project_id: project.id)

      expect(subscription).to be_rejected
    end

    context 'on an issue' do
      let_it_be(:noteable) { create(:issue, project: project) }

      it_behaves_like 'handle subscription based on user access'
    end

    context 'on a merge request' do
      let_it_be(:noteable) { create(:merge_request, source_project: project) }

      it_behaves_like 'handle subscription based on user access'
    end
  end
end
