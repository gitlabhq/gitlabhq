require 'spec_helper'

describe 'layouts/nav/_new_group_sidebar' do
  before do
    assign(:group, create(:group))
  end

  describe 'group issue boards link' do
    it 'is not visible when there is no valid license' do
      stub_licensed_features(group_issue_boards: false)

      render

      expect(rendered).not_to have_text 'Boards'
    end

    it 'is not visible when there is no valid license' do
      stub_licensed_features(group_issue_boards: true)

      render

      expect(rendered).to have_text 'Boards'
    end
  end
end
