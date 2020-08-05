# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Oauth::TokensController do
  it 'includes Two-factor enforcement concern' do
    expect(described_class.included_modules.include?(EnforcesTwoFactorAuthentication)).to eq(true)
  end
end
