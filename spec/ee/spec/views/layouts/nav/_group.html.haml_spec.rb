require 'spec_helper'

describe 'layouts/nav/_group' do
  before do
    assign(:group, create(:group))
  end

  describe 'contribution analytics tab' do
    it 'is not visible when there is no valid license and we dont show promotions' do
      stub_licensed_features(contribution_analytics: false)

      render

      expect(rendered).not_to have_text 'Contribution Analytics'
    end

    it 'is visible when there is no valid license but we show promotions' do
      stub_licensed_features(contribution_analytics: false)
      let!(:license) { nil }

      render

      expect(rendered).to have_text 'Contribution Analytics'
    end

    it 'is visible' do
      stub_licensed_features(contribution_analytics: true)

      render

      expect(rendered).to have_text 'Contribution Analytics'
    end
  end
end
