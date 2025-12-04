# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Claim for User', feature_category: :cell do
  subject! { build(:user, email: email.email, emails: [email]) }

  let(:email) { build(:email) }

  shared_context 'with claims records for User' do
    def claims_records(only: {})
      claims_records_for(subject, only: only) +
        claims_records_for(email, only: only)
    end
  end

  it_behaves_like 'creating new claims' do
    include_context 'with claims records for User'
  end

  it_behaves_like 'deleting existing claims' do
    include_context 'with claims records for User'
  end

  it_behaves_like 'updating existing claims' do
    let(:transform_attributes) { { username: subject.username.reverse } }

    include_context 'with claims records for User'
  end
end
