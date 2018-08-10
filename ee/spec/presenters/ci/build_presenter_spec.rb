# frozen_string_literal: true
require 'spec_helper'

describe Ci::BuildPresenter do
  subject(:presenter) { described_class.new(build) }

  describe '#callout_failure_message' do
    let(:build) { create(:ee_ci_build, :protected_environment_failure) }

    it 'returns a verbose failure reason' do
      description = presenter.callout_failure_message
      expect(description).to eq('The environment this job is deploying to is protected. Only users with permission may successfully run this job')
    end
  end
end
