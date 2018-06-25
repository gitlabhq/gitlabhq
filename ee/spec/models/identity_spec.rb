require 'spec_helper'

describe Identity do
  describe 'relations' do
    it { is_expected.to belong_to(:saml_provider) }
  end

  context 'with saml_provider' do
    it 'allows user to have records with different groups' do
      _identity_one = create(:identity, provider: 'group_saml', saml_provider: create(:saml_provider))
      identity_two = create(:identity, provider: 'group_saml', saml_provider: create(:saml_provider))

      expect(identity_two).to be_valid
    end
  end
end
