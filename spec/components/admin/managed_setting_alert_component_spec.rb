# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::ManagedSettingAlertComponent, feature_category: :settings do
  context 'when the managing party is known' do
    before do
      allow(Gitlab::ManagedSettings).to receive(:managed_by).and_return('GitLab Helm Chart')
    end

    it 'names it in the alert' do
      render_inline(described_class.new)

      expect(page).to have_text('This setting is managed by GitLab Helm Chart and cannot be changed from here.')
    end
  end

  context 'when the managing party is unknown' do
    before do
      allow(Gitlab::ManagedSettings).to receive(:managed_by).and_return(nil)
    end

    it 'renders a generic message' do
      render_inline(described_class.new)

      expect(page).to have_text('This setting is managed and cannot be changed from here.')
    end
  end
end
