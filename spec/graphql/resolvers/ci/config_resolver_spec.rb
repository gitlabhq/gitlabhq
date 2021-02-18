# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::ConfigResolver do
  include GraphqlHelpers

  describe '#resolve' do
    before do
      ci_lint_double = instance_double(::Gitlab::Ci::Lint)
      allow(ci_lint_double).to receive(:validate).and_return(fake_result)

      allow(::Gitlab::Ci::Lint).to receive(:new).and_return(ci_lint_double)
    end

    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :repository, creator: user, namespace: user.namespace) }

    subject(:response) do
      resolve(described_class,
              args: { project_path: project.full_path, content: content },
              ctx:  { current_user: user })
    end

    context 'with a valid .gitlab-ci.yml' do
      let(:fake_result) do
        ::Gitlab::Ci::Lint::Result.new(
          merged_yaml: content,
          jobs: [],
          errors: [],
          warnings: []
        )
      end

      let_it_be(:content) do
        File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci_includes.yml'))
      end

      it 'lints the ci config file and returns the merged yaml file' do
        expect(response[:merged_yaml]).to eq(content)
        expect(response[:status]).to eq(:valid)
        expect(response[:errors]).to be_empty
      end
    end

    context 'with an invalid .gitlab-ci.yml' do
      let(:content) { 'invalid' }

      let(:fake_result) do
        Gitlab::Ci::Lint::Result.new(
          jobs: [],
          merged_yaml: content,
          errors: ['Invalid configuration format'],
          warnings: []
        )
      end

      it 'responds with errors about invalid syntax' do
        expect(response[:status]).to eq(:invalid)
        expect(response[:errors]).to eq(['Invalid configuration format'])
      end
    end
  end
end
