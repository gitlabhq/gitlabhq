# frozen_string_literal: true
require 'spec_helper'

describe ProtectedEnvironments::EnvironmentDropdownService, '#roles' do
  let(:roles) do
    [
      { id: 40, text: 'Maintainers', before_divider: true },
      { id: 30, text: 'Developers + Maintainers', before_divider: true }
    ]
  end

  subject { described_class.roles_hash }

  describe '#roles' do
    it 'returns a hash with access levels for allowed to deploy option' do
      expect(subject[:roles]).to match_array(roles)
    end
  end
end
