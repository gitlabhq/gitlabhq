# frozen_string_literal: true
require 'spec_helper'

describe EnvironmentEntity do
  using RSpec::Parameterized::TableSyntax

  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:environment) { create(:environment, :with_review_app, ref: 'development', project: project) }
  let(:protected_environment) { create(:protected_environment, name: environment.name, project: project) }

  let(:entity) do
    described_class.new(environment, request: double(current_user: user, project: project))
  end

  before do
    project.repository.add_branch(user, 'development', project.commit.id)
  end

  describe '#can_stop' do
    subject { entity.as_json[:can_stop] }

    it_behaves_like 'protected environments access'
  end

  describe '#terminal_path' do
    subject { entity.as_json.include?(:terminal_path) }

    before do
      allow(environment).to receive(:has_terminals?).and_return(true)
    end

    it_behaves_like 'protected environments access', false
  end
end
