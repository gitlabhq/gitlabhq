# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::BlobsResolver, feature_category: :source_code_management do
  include GraphqlHelpers
  include RepoHelpers

  describe '#resolve' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :repository) }

    let(:repository) { project.repository }
    let(:paths) { [] }
    let(:ref) { nil }
    let(:ref_type) { nil }

    let(:obj) { repository }
    let(:args) { { paths: paths, ref: ref, ref_type: ref_type } }
    let(:ctx) { { current_user: user } }
    let(:lookahead) { :not_given }

    shared_examples_for 'returns all requested blobs' do
      it { is_expected.to match_array(paths.map { |path| have_attributes(path: path) }) }
    end

    shared_examples_for 'returns the readme' do
      it { is_expected.to contain_exactly(have_attributes(path: 'README.md')) }
    end

    shared_examples_for 'returns nothing' do
      it { is_expected.to be_empty }
    end

    shared_examples_for 'raises an argument error' do
      it { expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ArgumentError, error) { resolve_blobs } }
    end

    subject(:resolve_blobs) { resolve(described_class, obj:, args:, ctx:, lookahead:) }

    context 'when unauthorized' do
      it 'generates an error' do
        expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) { resolve_blobs }
      end
    end

    context 'when authorized' do
      before do
        project.add_developer(user)
      end

      context 'using no filter' do
        it_behaves_like 'returns nothing'
      end

      context 'using paths filter' do
        let(:paths) { ['files/pdf/test.pdf', 'README.md'] }

        context 'with valid path' do
          let(:paths) { ['README.md'] }

          it_behaves_like 'returns all requested blobs'
        end

        context 'with valid paths' do
          let(:paths) { ['README.md', 'CHANGELOG'] }

          it_behaves_like 'returns all requested blobs'
        end

        context 'specifying a non-existent blob' do
          let(:paths) { ['non-existent'] }

          it_behaves_like 'returns nothing'
        end

        context 'when specifying a branch ref' do
          let(:ref) { 'add-pdf-file' }
          let(:args) { { paths: paths, ref: ref, ref_type: ref_type } }
          let(:paths) { ['files/pdf/test.pdf', 'README.md'] }

          context 'and no ref_type is specified' do
            let(:ref_type) { nil }

            it_behaves_like 'returns all requested blobs'

            context 'and a tag with the same name exists' do
              let(:ref) { SecureRandom.uuid }

              before do
                project.repository.create_branch(ref)
                project.repository.add_tag(project.owner, sample_commit.id, ref)
              end

              it_behaves_like 'returns the readme'
            end
          end

          context 'and ref_type is for branches' do
            let(:ref_type) { 'heads' }

            it_behaves_like 'returns all requested blobs'
          end

          context 'and ref_type is for tags' do
            let(:ref_type) { 'tags' }

            it_behaves_like 'returns nothing'
          end
        end

        context 'when specifying a tag ref' do
          let(:ref) { 'v1.0.0' }

          context 'and no ref_type is specified' do
            it_behaves_like 'returns the readme'
          end

          context 'and ref_type is for tags' do
            let(:ref_type) { 'tags' }

            it_behaves_like 'returns the readme'
          end

          context 'and ref_type is for branches' do
            let(:ref_type) { 'heads' }

            it_behaves_like 'returns nothing'
          end
        end

        context 'when specifying HEAD ref' do
          let(:ref) { 'HEAD' }

          it_behaves_like 'returns the readme'
        end

        context 'when specifying an invalid ref' do
          let(:ref) { 'ma:in' }

          it_behaves_like 'raises an argument error' do
            let(:error) { 'Ref is not valid' }
          end
        end

        context 'when passing an empty ref' do
          let(:ref) { '' }

          it_behaves_like 'raises an argument error' do
            let(:error) { 'Ref is not valid' }
          end
        end

        context "when the blobs' data exceeds the limit" do
          let(:ref) { 'master' }
          let(:ref_type) { 'heads' }
          let(:qualified_ref) { ExtractsRef::RefExtractor.qualify_ref(ref, ref_type) }
          let(:ref_path_pairs) { paths.map { |path| [qualified_ref, path] } }
          let(:blobs) { project.repository.blobs_at(ref_path_pairs) }
          let(:data) { 'oversized' }
          let(:over_limit) { described_class::TOTAL_BLOB_DATA_SIZE_LIMIT + 1 }
          let(:lookahead) { instance_double(GraphQL::Execution::Lookahead) }
          let(:edges_lookahead) { instance_double(GraphQL::Execution::Lookahead) }
          let(:nodes_lookahead) do
            selections = described_class::DATA_FIELDS.map do |name|
              instance_double(GraphQL::Execution::Lookahead, name: name)
            end
            instance_double(GraphQL::Execution::Lookahead, selections: selections)
          end

          before do
            allow(project.repository).to receive(:blobs_at).and_return(blobs)
            blobs.each do |blob|
              allow(blob).to receive_messages(size: over_limit, data: data)
            end
            allow(lookahead).to receive(:selection).with(:nodes)
          end

          context 'when a single blob is requested' do
            let(:paths) { ['README.md'] }

            before do
              allow(lookahead).to receive(:selection).with(:nodes).and_return(nodes_lookahead)
            end

            it_behaves_like 'returns all requested blobs'
          end

          context 'when multiple blobs are requested' do
            let(:paths) { ['README.md', 'CHANGELOG'] }

            context 'when data fields are requested' do
              context 'via nodes connection field' do
                before do
                  allow(lookahead).to receive(:selection).with(:nodes).and_return(nodes_lookahead)
                  # Ensure that requesting non-data fields in the `edges.node`
                  # node doesn't bypass the check
                  allow(lookahead).to receive(:selection).with(:edges).and_return(negative_lookahead)
                end

                it_behaves_like 'raises an argument error' do
                  let(:error) do
                    total = ActiveSupport::NumberHelper::NumberToHumanSizeConverter.convert(over_limit * blobs.size, {})
                    format(described_class::SIZE_LIMIT_EXCEEDED_ERROR, total: total)
                  end
                end
              end

              context 'via edges.node connection field' do
                before do
                  allow(lookahead).to receive(:selection).with(:edges).and_return(edges_lookahead)
                  allow(edges_lookahead).to receive(:selection).with(:node).and_return(nodes_lookahead)
                  # Ensure that requesting non-data fields in the `nodes` node
                  # doesn't bypass the check
                  allow(lookahead).to receive(:selection).with(:nodes).and_return(negative_lookahead)
                end

                it_behaves_like 'raises an argument error' do
                  let(:error) do
                    total = ActiveSupport::NumberHelper::NumberToHumanSizeConverter.convert(over_limit * blobs.size, {})
                    format(described_class::SIZE_LIMIT_EXCEEDED_ERROR, total: total)
                  end
                end
              end
            end

            context 'when data fields are not requested' do
              let(:lookahead) { negative_lookahead }

              it_behaves_like 'returns all requested blobs'
            end
          end
        end
      end
    end
  end
end
