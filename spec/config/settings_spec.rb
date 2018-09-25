require 'spec_helper'

describe Settings do
  describe 'omniauth' do
    it 'defaults to enabled' do
      expect(described_class.omniauth.enabled).to be true
    end
  end
end
