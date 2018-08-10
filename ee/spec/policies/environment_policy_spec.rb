# frozen_string_literal: true
require 'spec_helper'

describe EnvironmentPolicy do
  using RSpec::Parameterized::TableSyntax

  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:environment) { create(:environment, :with_review_app, ref: 'development', project: project) }

  before do
    project.repository.add_branch(user, 'development', project.commit.id)
  end

  describe '#stop_environment' do
    subject { user.can?(:stop_environment, environment) }

    it_behaves_like 'protected environments access'
  end

  describe '#create_environment_terminal' do
    subject { user.can?(:create_environment_terminal, environment) }

    it_behaves_like 'protected environments access', false
  end
end
