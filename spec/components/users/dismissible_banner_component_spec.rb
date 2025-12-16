# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::DismissibleBannerComponent, feature_category: :acquisition do
  context 'with user dismissible banner behavior' do
    let(:callout_model) { Users::Callout }
    let(:dismissal_method) { :dismissed_callout? }
    let(:dismiss_options) { { user: user, feature_id: feature_id } }
    let(:dismiss_endpoint) { callouts_path }

    it_behaves_like 'dismissible banner component'
  end
end
