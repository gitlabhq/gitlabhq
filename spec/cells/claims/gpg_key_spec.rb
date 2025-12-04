# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Claim for GpgKey', feature_category: :cell do
  let_it_be(:user) { create(:user) }

  subject! { build(:gpg_key_with_subkeys, user: user) }

  shared_context 'with claims records for GpgKey' do
    def claims_records(only: {})
      claims_records_for(subject, only: only) +
        subject.subkeys.flat_map do |subkey|
          claims_records_for(subkey, only: only)
        end
    end
  end

  it_behaves_like 'creating new claims' do
    include_context 'with claims records for GpgKey'
  end

  it_behaves_like 'deleting existing claims' do
    include_context 'with claims records for GpgKey'
  end
end
