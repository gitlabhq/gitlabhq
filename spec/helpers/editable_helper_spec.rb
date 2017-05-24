require 'spec_helper'

describe EditableHelper do
  describe '#updated_at_by' do
    let(:user) { create(:user) }
    let(:unedited_editable) { create(:issue) }
    let(:edited_editable) { create(:issue, last_edited_by: user, created_at: 3.days.ago, updated_at: 2.days.ago, last_edited_at: 2.days.ago) }
    let(:edited_updated_at_by) do
      {
        updated_at: edited_editable.updated_at.to_time.iso8601,
        updated_by: {
          name: user.name,
          path: user_path(user)
        }
      }
    end

    it { expect(helper.updated_at_by(unedited_editable)).to eq({}) }
    it { expect(helper.updated_at_by(edited_editable)).to eq(edited_updated_at_by) }
  end
end
