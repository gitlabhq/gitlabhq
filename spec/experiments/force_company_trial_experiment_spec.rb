# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ForceCompanyTrialExperiment, :experiment do
  subject { described_class.new(current_user: user) }

  let(:user) { create(:user, setup_for_company: setup_for_company) }
  let(:setup_for_company) { true }

  context 'when a user is setup_for_company' do
    it 'is not excluded' do
      expect(subject).not_to exclude(user: user)
    end
  end

  context 'when a user is not setup_for_company' do
    let(:setup_for_company) { nil }

    it 'is excluded' do
      expect(subject).to exclude(user: user)
    end
  end
end
