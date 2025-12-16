# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Experimental::O11yServiceSettingsHelper, feature_category: :observability do
  describe '#o11y_per_page_options' do
    it 'returns the allowed per-page options including controller MAX_PER_PAGE' do
      expect(helper.o11y_per_page_options).to eq(
        [10, 20, 50, Experimental::O11yServiceSettingsController::MAX_PER_PAGE]
      )
    end
  end
end
