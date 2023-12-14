# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::Catalog::ResourceResolver, feature_category: :pipeline_composition do
  include GraphqlHelpers

  let_it_be(:namespace) { create(:group) }
  let_it_be(:project) { create(:project, :private, namespace: namespace) }
  let_it_be(:resource) { create(:ci_catalog_resource, :published, project: project) }
  let_it_be(:user) { create(:user) }

  describe '#resolve' do
    context 'when id argument is provided' do
      context 'when the user is authorised to view the resource' do
        before_all do
          namespace.add_developer(user)
        end

        context 'when resource is found' do
          it 'returns a single CI/CD Catalog resource' do
            result = resolve(described_class, ctx: { current_user: user },
              args: { id: resource.to_global_id })

            expect(result.id).to eq(resource.id)
            expect(result.class).to eq(Ci::Catalog::Resource)
          end
        end

        context 'when resource is not found' do
          it 'raises ResourceNotAvailable error' do
            result = resolve(described_class, ctx: { current_user: user },
              args: { id: GlobalID.new(
                ::Gitlab::GlobalId.build(model_name: '::Ci::Catalog::Resource', id: "not-a-real-id")
              ) })

            expect(result).to be_a(::Gitlab::Graphql::Errors::ResourceNotAvailable)
          end
        end
      end

      context 'when user is not authorised to view the resource' do
        it 'raises ResourceNotAvailable error' do
          result = resolve(described_class, ctx: { current_user: user },
            args: { id: resource.to_global_id })

          expect(result).to be_a(::Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end
    end

    context 'when full_path argument is provided' do
      context 'when the user is authorised to view the resource' do
        before_all do
          namespace.add_developer(user)
        end

        context 'when resource is found' do
          it 'returns a single CI/CD Catalog resource' do
            result = resolve(described_class, ctx: { current_user: user },
              args: { full_path: resource.project.full_path })

            expect(result.id).to eq(resource.id)
            expect(result.class).to eq(Ci::Catalog::Resource)
          end
        end

        context 'when resource is not found' do
          it 'raises ResourceNotAvailable error' do
            result = resolve(described_class, ctx: { current_user: user },
              args: { full_path: "project/non_exisitng_resource" })

            expect(result).to be_a(::Gitlab::Graphql::Errors::ResourceNotAvailable)
          end
        end

        context 'when project is not a catalog resource' do
          let_it_be(:project) { create(:project, :private, namespace: namespace) }

          it 'raises ResourceNotAvailable error' do
            result = resolve(described_class, ctx: { current_user: user }, args: { full_path: project.full_path })

            expect(result).to be_a(::Gitlab::Graphql::Errors::ResourceNotAvailable)
          end
        end
      end

      context 'when user is not authorised to view the resource' do
        it 'raises ResourceNotAvailable error' do
          result = resolve(described_class, ctx: { current_user: user },
            args: { full_path: resource.project.full_path })

          expect(result).to be_a(::Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end
    end

    context 'when neither id nor full_path argument is provided' do
      before_all do
        namespace.add_developer(user)
      end
      it 'raises ArgumentError' do
        expect_graphql_error_to_be_created(::Gitlab::Graphql::Errors::ArgumentError,
          "Exactly one of 'id' or 'full_path' arguments is required.") do
          resolve(described_class, ctx: { current_user: user },
            args: {})
        end
      end
    end

    context 'when both full_path and id arguments are provided' do
      before_all do
        namespace.add_developer(user)
      end

      it 'raises ArgumentError' do
        expect_graphql_error_to_be_created(::Gitlab::Graphql::Errors::ArgumentError,
          "Exactly one of 'id' or 'full_path' arguments is required.") do
          resolve(described_class, ctx: { current_user: user },
            args: { full_path: resource.project.full_path, id: resource.to_global_id })
        end
      end
    end
  end
end
