# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::Catalog::ResourcesResolver, feature_category: :pipeline_composition do
  include GraphqlHelpers

  let_it_be(:namespace) { create(:group) }
  let_it_be(:private_namespace_project) { create(:project, :private, name: 'z private test', namespace: namespace) }
  let_it_be(:private_namespace_project_2) { create(:project, :private, name: 'a private test', namespace: namespace) }
  let_it_be(:public_namespace_project) do
    create(:project, :public, name: 'public', description: 'Test', namespace: namespace)
  end

  let_it_be(:internal_project) { create(:project, :internal, name: 'internal') }
  let_it_be(:private_resource) { create(:ci_catalog_resource, :published, project: private_namespace_project) }
  let_it_be(:private_resource_2) { create(:ci_catalog_resource, project: private_namespace_project_2) }
  let_it_be(:public_resource) do
    create(:ci_catalog_resource, :published, project: public_namespace_project, verification_level: 100)
  end

  let_it_be(:internal_resource) { create(:ci_catalog_resource, :published, project: internal_project) }
  let_it_be(:user) { create(:user) }

  let(:ctx) { { current_user: user } }
  let(:search) { nil }
  let(:sort) { nil }
  let(:scope) { nil }
  let(:project_path) { nil }
  let(:verification_level) { nil }
  let(:topics) { [] }

  let(:args) do
    {
      project_path: project_path,
      sort: sort,
      search: search,
      scope: scope,
      verification_level: verification_level,
      topics: topics
    }.compact
  end

  subject(:result) { resolve(described_class, ctx: ctx, args: args) }

  describe '#resolve' do
    context 'with an authorized user' do
      before_all do
        namespace.add_reporter(user)
        internal_project.add_reporter(user)
      end

      context 'when sort argument is not provided' do
        it 'returns all catalog resources sorted by descending created date' do
          expect(result.items.pluck(:name)).to eq(['internal', 'public', 'z private test'])
        end
      end

      context 'when the sort argument is provided' do
        let(:sort) { 'NAME_DESC' }

        it 'returns all published catalog resources sorted by descending name' do
          expect(result.items.pluck(:name)).to eq(['z private test', 'public', 'internal'])
        end
      end

      context 'when the search argument is provided' do
        let(:search) { 'test' }

        it 'returns published catalog resources that match the search term' do
          expect(result.items.pluck(:name)).to contain_exactly('z private test', 'public')
        end
      end

      context 'with scope argument' do
        it 'defaults to :all and returns all catalog resources' do
          expect(result.items.to_a.size).to be(3)
          expect(result.items.pluck(:name)).to contain_exactly('public', 'internal', 'z private test')
        end

        context 'when the scope argument is :namespaces' do
          let(:scope) { 'NAMESPACES' }

          it 'returns projects of the namespaces the user is a member of' do
            namespace = create(:namespace, owner: user)
            internal_public_project = create(:project, :internal, name: 'internal public', namespace: namespace)
            create(:ci_catalog_resource, :published, project: internal_public_project)

            expect(result.items.to_a.size).to be(4)
            expect(result.items.pluck(:name)).to contain_exactly('public', 'internal public', 'internal',
              'z private test')
          end
        end

        context 'when the scope is invalid' do
          let(:scope) { 'INVALID' }

          it 'defaults to :all and returns all catalog resources' do
            expect(result.items.to_a.size).to be(3)
            expect(result.items.pluck(:name)).to contain_exactly('public', 'internal', 'z private test')
          end
        end
      end

      context 'with verification_level argument' do
        let(:verification_level) { :gitlab_maintained }

        it 'returns published catalog resources that match the verification level' do
          expect(result.items.pluck(:name)).to contain_exactly('public')
        end
      end

      context 'with topics argument' do
        let_it_be(:topic_ruby) { create(:topic, name: 'ruby') }
        let_it_be(:topic_rails) { create(:topic, name: 'rails') }
        let_it_be(:topic_gitlab) { create(:topic, name: 'gitlab') }

        before_all do
          create(:project_topic, project: public_namespace_project, topic: topic_ruby)
          create(:project_topic, project: public_namespace_project, topic: topic_rails)
          create(:project_topic, project: internal_project, topic: topic_gitlab)
        end

        context 'when filtering by multiple topics' do
          let(:topics) { %w[ruby gitlab] }

          it 'returns resources with projects matching any of the given topic names' do
            ordered_names = result.items.reorder('catalog_resources.name DESC').pluck(:name)
            expect(ordered_names).to eq(%w[public internal])
          end
        end

        context 'when filtering by a single topic' do
          let(:topics) { %w[ruby] }

          it 'returns resources with projects matching the topic name' do
            ordered_names = result.items.reorder('catalog_resources.name DESC').pluck(:name)
            expect(ordered_names).to contain_exactly('public')
          end
        end

        context 'when combining with other filters' do
          context 'with search' do
            let(:topics) { %w[ruby] }
            let(:search) { 'Test' }

            it 'returns resources matching both filters' do
              ordered_names = result.items.reorder('catalog_resources.name DESC').pluck(:name)
              expect(ordered_names).to contain_exactly('public')
            end
          end

          context 'with verification level' do
            let(:topics) { %w[ruby] }
            let(:verification_level) { :gitlab_maintained }

            it 'returns resources matching both filters' do
              ordered_names = result.items.reorder('catalog_resources.name DESC').pluck(:name)
              expect(ordered_names).to contain_exactly('public')
            end
          end

          context 'with scope' do
            let(:topics) { %w[ruby] }
            let(:scope) { 'NAMESPACES' }

            it 'returns resources matching both filters' do
              ordered_names = result.items.reorder('catalog_resources.name DESC').pluck(:name)
              expect(ordered_names).to contain_exactly('public')
            end
          end

          context 'with sort' do
            let(:topics) { %w[ruby gitlab] }
            let(:sort) { 'NAME_DESC' }

            it 'returns filtered resources in sorted order' do
              ordered_names = result.items.reorder('catalog_resources.name DESC').pluck(:name)
              expect(ordered_names).to eq(%w[public internal])
            end
          end
        end

        context 'when filtering by non-existent topics' do
          let(:topics) { %w[nonexistent] }

          it 'returns no resources' do
            expect(result.items).to be_empty
          end
        end

        context 'when topics argument is empty' do
          let(:topics) { [] }

          it 'returns all visible resources' do
            ordered_names = result.items.reorder('catalog_resources.name DESC').pluck(:name)
            expect(ordered_names).to contain_exactly('public', 'internal', 'z private test')
          end
        end
      end
    end

    context 'when the user is anonymous' do
      let_it_be(:user) { nil }

      it 'returns only public projects' do
        expect(result.items.to_a.size).to be(1)
        expect(result.items.pluck(:name)).to contain_exactly('public')
      end
    end
  end

  describe 'preloads' do
    before_all do
      namespace.add_reporter(user)
      internal_project.add_reporter(user)
    end

    it 'avoids N+1 queries when accessing versions and archived fields' do
      # Create versions with components for resources
      version1 = create(:ci_catalog_resource_version, catalog_resource: public_resource,
        project: public_namespace_project)
      create(:ci_catalog_resource_component, version: version1, catalog_resource: public_resource,
        project: public_namespace_project)

      version2 = create(:ci_catalog_resource_version, catalog_resource: private_resource,
        project: private_namespace_project)
      create(:ci_catalog_resource_component, version: version2, catalog_resource: private_resource,
        project: private_namespace_project)

      # Query that requests versions and archived fields
      query = <<~GQL
        query {
          ciCatalogResources {
            nodes {
              id
              archived
              versions {
                nodes {
                  id
                  components {
                    nodes {
                      id
                    }
                  }
                }
              }
            }
          }
        }
      GQL

      control = ActiveRecord::QueryRecorder.new do
        GitlabSchema.execute(query, context: { current_user: user }).to_h
      end

      # Add more resources with versions
      version3 = create(:ci_catalog_resource_version, catalog_resource: internal_resource,
        project: internal_project)
      create(:ci_catalog_resource_component, version: version3, catalog_resource: internal_resource,
        project: internal_project)

      expect do
        GitlabSchema.execute(query, context: { current_user: user }).to_h
      end.not_to exceed_query_limit(control)
    end
  end
end
