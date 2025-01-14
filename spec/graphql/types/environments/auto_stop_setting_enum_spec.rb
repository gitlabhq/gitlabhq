# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Environments::AutoStopSettingEnum, feature_category: :environment_management do
  it 'exposes all auto stop settings' do
    expect(described_class.values.keys).to include(*%w[ALWAYS WITH_ACTION])
  end
end
