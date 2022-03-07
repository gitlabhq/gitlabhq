# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItemIdType do
  let_it_be(:project) { create(:project) }
  let_it_be(:work_item) { create(:work_item, project: project) }
  let_it_be(:issue) { create(:issue, project: project) }

  let(:work_item_gid) { work_item.to_gid }
  let(:issue_gid) { issue.to_gid }
  let(:ctx) { {} }

  describe '.coerce_input' do
    it 'can coerce valid issue input' do
      coerced = described_class.coerce_input(issue_gid.to_s, ctx)

      expect(coerced).to eq(WorkItem.find(issue.id).to_gid)
    end

    it 'can coerce valid work item input' do
      coerced = described_class.coerce_input(work_item_gid.to_s, ctx)

      expect(coerced).to eq(work_item_gid)
    end

    it 'fails for other input types' do
      project_gid = project.to_gid

      expect { described_class.coerce_input(project_gid.to_s, ctx) }
        .to raise_error(GraphQL::CoercionError, "#{project_gid.to_s.inspect} does not represent an instance of WorkItem")
    end
  end

  describe '.coerce_result' do
    it 'can coerce issue results and return a WorkItem global ID' do
      expect(described_class.coerce_result(issue_gid, ctx)).to eq(WorkItem.find(issue.id).to_gid.to_s)
    end

    it 'can coerce work item results' do
      expect(described_class.coerce_result(work_item_gid, ctx)).to eq(work_item_gid.to_s)
    end

    it 'fails for other input types' do
      project_gid = project.to_gid

      expect { described_class.coerce_result(project_gid, ctx) }
        .to raise_error(GraphQL::CoercionError, "Expected a WorkItem ID, got #{project_gid}")
    end
  end
end
