# frozen_string_literal: true
require 'spec_helper'

describe Ci::BuildPolicy do
  using RSpec::Parameterized::TableSyntax

  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:pipeline) { create(:ci_empty_pipeline, project: project) }

  describe '#update_build?' do
    let(:environment) { create(:environment, project: project, name: 'production') }
    let(:build) { create(:ee_ci_build, pipeline: pipeline, environment: 'production', ref: 'development') }

    subject { user.can?(:update_build, build) }

    it_behaves_like 'protected environments access'
  end
end
