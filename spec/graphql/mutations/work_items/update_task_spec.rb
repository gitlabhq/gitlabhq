# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::WorkItems::UpdateTask do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user).tap { |user| project.add_developer(user) } }
  let_it_be(:referenced_work_item, refind: true) { create(:work_item, project: project, title: 'REFERENCED') }
  let_it_be(:parent_work_item) do
    create(:work_item, project: project, description: "- [ ] #{referenced_work_item.to_reference}+")
  end

  let(:task_params) { { title: 'UPDATED' } }
  let(:task_input) { { id: referenced_work_item.to_global_id }.merge(task_params) }
  let(:input) { { id: parent_work_item.to_global_id, task_data: task_input } }
  let(:mutation) { described_class.new(object: nil, context: { current_user: current_user }, field: nil) }

  describe '#resolve' do
    subject(:resolve) do
      mutation.resolve(**input)
    end

    before do
      stub_spam_services
    end

    context 'when user has sufficient permissions' do
      let(:current_user) { developer }

      it 'expires etag cache for parent work item' do
        allow(WorkItem).to receive(:find).and_call_original
        allow(WorkItem).to receive(:find).with(parent_work_item.id.to_s).and_return(parent_work_item)

        expect(parent_work_item).to receive(:expire_etag_cache)

        resolve
      end
    end
  end
end
