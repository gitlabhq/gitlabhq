# frozen_string_literal: true
require 'spec_helper'

describe JobEntity do
  using RSpec::Parameterized::TableSyntax

  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:request) { double('request') }
  let(:entity) { described_class.new(job, request: request) }
  let(:environment) { create(:environment, project: project) }

  before do
    allow(request).to receive(:current_user).and_return(user)
  end

  describe '#playable?' do
    let(:job) { create(:ci_build, :manual, project: project, environment: environment.name, ref: 'development') }

    subject { entity.as_json[:playable] }

    it_behaves_like 'protected environments access'
  end

  describe '#retryable?' do
    let(:job) { create(:ci_build, :failed, project: project, environment: environment.name, ref: 'development') }

    subject { entity.as_json.include?(:retry_path) }

    it_behaves_like 'protected environments access'
  end
end
