# frozen_string_literal: true
require 'spec_helper'

describe Gitlab::HookData::IssueBuilder do
  set(:issue) { create(:issue) }
  let(:builder) { described_class.new(issue) }

  describe '#build' do
    let(:data) { builder.build }

    it 'includes safe attribute' do
      %w[
        assignee_id
        author_id
        closed_at
        confidential
        created_at
        description
        due_date
        id
        iid
        last_edited_at
        last_edited_by_id
        milestone_id
        moved_to_id
        project_id
        relative_position
        state
        time_estimate
        title
        updated_at
        updated_by_id
        weight
      ].each do |key|
        expect(data).to include(key)
      end
    end

    it 'includes additional attr' do
      expect(data).to include(:weight)
    end

    context 'when the issue has an image in the description' do
      let(:issue_with_description) { create(:issue, description: 'test![Issue_Image](/uploads/abc/Issue_Image.png)') }
      let(:builder) { described_class.new(issue_with_description) }

      it 'sets the image to use an absolute URL' do
        expect(data[:description]).to eq("test![Issue_Image](#{Settings.gitlab.url}/uploads/abc/Issue_Image.png)")
      end
    end
  end
end
