# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::ConfigResolver, feature_category: :continuous_integration do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:sha) { nil }

    let_it_be(:content) do
      File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci_includes.yml'))
    end

    subject(:response) do
      resolve(
        described_class,
        args: { project_path: project.full_path, content: content, sha: sha },
        ctx: { current_user: user }
      )
    end

    shared_examples 'a valid config file' do
      let(:fake_result) do
        ::Gitlab::Ci::Lint::Result.new(
          merged_yaml: content,
          jobs: [],
          errors: [],
          warnings: [],
          includes: []
        )
      end

      it 'lints the ci config file and returns the merged yaml file' do
        expect(response[:status]).to eq(:valid)
        expect(response[:merged_yaml]).to eq(content)
        expect(response[:includes]).to eq([])
        expect(response[:errors]).to be_empty
        expect(::Gitlab::Ci::Lint).to have_received(:new)
          .with(current_user: user, project: project, sha: sha, verify_project_sha: true)
      end
    end

    context 'when the user can create a pipeline' do
      let(:ci_lint) do
        ci_lint_double = instance_double(::Gitlab::Ci::Lint)
        allow(ci_lint_double).to receive(:validate).and_return(fake_result)

        ci_lint_double
      end

      before do
        allow(::Gitlab::Ci::Lint).to receive(:new).and_return(ci_lint)

        project.add_developer(user)
      end

      context 'with a valid .gitlab-ci.yml' do
        context 'with a sha' do
          let(:sha) { '1231231' }

          it_behaves_like 'a valid config file'
        end

        context 'without a sha' do
          it_behaves_like 'a valid config file'
        end
      end

      context 'with an invalid .gitlab-ci.yml' do
        let(:content) { 'invalid' }

        let(:fake_result) do
          Gitlab::Ci::Lint::Result.new(
            jobs: [],
            merged_yaml: content,
            errors: ['Invalid configuration format'],
            warnings: [],
            includes: []
          )
        end

        it 'responds with errors about invalid syntax' do
          expect(response[:status]).to eq(:invalid)
          expect(response[:errors]).to match_array(['Invalid configuration format'])
        end
      end

      context 'with an invalid SHA' do
        let_it_be(:sha) { ':' }

        let(:ci_lint) do
          ci_lint_double = instance_double(::Gitlab::Ci::Lint)
          allow(ci_lint_double).to receive(:validate).and_raise(GRPC::InvalidArgument)

          ci_lint_double
        end

        it 'logs the invalid SHA to Sentry' do
          expect(Gitlab::ErrorTracking).to receive(:track_and_raise_exception)
            .with(GRPC::InvalidArgument, sha: ':')

          response
        end
      end
    end

    context 'when the user cannot create a pipeline' do
      before do
        project.add_guest(user)
      end

      it 'returns an error stating that the user cannot access the linting' do
        expect(response).to be_instance_of(::Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end
  end
end
