# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Organizations::OrganizationsFinder, feature_category: :organization do
  let_it_be(:first_organization) { create(:organization, name: 'First Organization') }
  let_it_be(:second_organization) { create(:organization, name: 'Second Organization') }
  let_it_be(:user) { create(:user, organization: first_organization) }

  let(:params) { {} }

  subject(:finder) { described_class.new(user, params).execute }

  it { is_expected.to contain_exactly(first_organization, second_organization) }

  describe 'search' do
    context 'when searching by name' do
      let(:params) { { search: first_organization.name } }

      it { is_expected.to contain_exactly(first_organization) }
    end

    context 'when searching by path' do
      let(:params) { { search: first_organization.path } }

      it { is_expected.to contain_exactly(first_organization) }
    end
  end
end
