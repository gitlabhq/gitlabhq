# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::NamespaceProjectsResolver, feature_category: :groups_and_projects do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let(:ctx) { { current_user: current_user } }
  let(:args) { default_args }
  let(:default_args) do
    {
      include_subgroups: false,
      include_archived: true,
      not_aimed_for_deletion: false,
      search: nil,
      sort: nil,
      ids: nil,
      with_issues_enabled: nil,
      with_merge_requests_enabled: nil,
      with_namespace_domain_pages: nil
    }
  end

  describe '#resolve' do
    subject { resolve(described_class, obj: namespace, args: args, ctx: ctx, arg_style: :internal) }

    let_it_be(:user_namespaced_projects) { create_list(:project, 3, namespace: current_user.namespace) }
    let_it_be(:group_namespaced_projects) do
      [
        create(:project, name: 'Project', path: 'project', namespace: group),
        create(:project, :archived, name: 'Test Project', path: 'test-project', namespace: group),
        create(:project, name: 'Test', path: 'test', namespace: group, marked_for_deletion_at: 1.day.ago, pending_delete: true)
      ]
    end

    let_it_be(:nested_group_projects) do
      create(:group, parent: group).then do |nested_group|
        [
          create(:project, group: nested_group),
          create(:project, group: nested_group, marked_for_deletion_at: 1.day.ago, pending_delete: true)
        ]
      end
    end

    before_all do
      group_namespaced_projects.each { |p| p.add_developer(current_user) }
      nested_group_projects.each { |p| p.add_developer(current_user) }
    end

    context "with a group" do
      let(:namespace) { group }
      let(:expected_projects) { group_namespaced_projects }

      it { is_expected.to contain_exactly(*expected_projects) }

      context 'when include_subgroups is true' do
        let(:args) { default_args.merge(include_subgroups: true) }
        let(:expected_projects) { group_namespaced_projects + nested_group_projects }

        it { is_expected.to contain_exactly(*expected_projects) }
      end

      context 'when not_aimed_for_deletion is true' do
        let(:args) { default_args.merge(not_aimed_for_deletion: true, include_subgroups: true) }
        let(:expected_projects) { group_namespaced_projects.first(2) << nested_group_projects.first }

        it { is_expected.to contain_exactly(*expected_projects) }
      end

      context 'when include_archived is false' do
        let(:args) { default_args.merge(include_archived: false) }
        let(:expected_projects) { group_namespaced_projects - [group_namespaced_projects.second] }

        it { is_expected.to contain_exactly(*expected_projects) }
      end

      context 'search and similarity sorting' do
        let(:project_names) { subject.map { |project| project['name'] } }

        let(:args) { default_args.merge(sort: :similarity, search: 'test') }

        it 'returns projects ordered by similarity to the search input' do
          expect(project_names.first).to eq('Test')
          expect(project_names.second).to eq('Test Project')
        end

        it 'filters out result that do not match the search input' do
          expect(project_names).not_to include('Project')
        end

        context 'when `search` parameter is not given' do
          let(:args) { default_args.merge(sort: :similarity, search: nil) }

          it 'returns all projects' do
            is_expected.to match_array(group_namespaced_projects)
          end
        end

        context 'when only search term is given' do
          let(:args) { default_args.merge(sort: nil, search: 'test') }

          it 'filters out result that do not match the search input, but does not sort them' do
            expect(project_names).to contain_exactly('Test', 'Test Project')
          end
        end
      end

      context 'ids filtering' do
        let(:args) { default_args.merge(include_subgroups: false) }

        context 'when ids is provided' do
          let(:args) { super().merge(ids: [group_namespaced_projects.last.to_global_id.to_s]) }

          it { is_expected.to contain_exactly(group_namespaced_projects.last) }
        end

        context 'when ids is nil' do
          let(:args) { super().merge(ids: nil) }

          it { is_expected.to contain_exactly(*group_namespaced_projects) }
        end
      end

      context 'with_namespace_domain_pages' do
        before do
          group_namespaced_projects[0...-1].each do |project|
            project.project_setting.update!(pages_unique_domain_enabled: false)
          end
          group_namespaced_projects.last.project_setting.update!(
            pages_unique_domain_enabled: true,
            pages_unique_domain: 'foo123.example.com'
          )
        end

        let(:args) { default_args.merge(with_namespace_domain_pages: true) }
        let(:expected_projects) { group_namespaced_projects[0...-1] }

        it { is_expected.to contain_exactly(*expected_projects) }
      end
    end

    context 'with an user namespace' do
      let(:namespace) { current_user.namespace }

      it { is_expected.to contain_exactly(*user_namespaced_projects) }
    end

    context "when passing a non existent, batch loaded namespace" do
      let(:namespace) do
        BatchLoader::GraphQL.for("non-existent-path").batch do |_fake_paths, loader, _|
          loader.call("non-existent-path", nil)
        end
      end

      it { is_expected.to be_empty }
    end
  end

  it 'has an high complexity regardless of arguments' do
    field = Types::BaseField.new(name: 'test', type: GraphQL::Types::String.connection_type, resolver_class: described_class, null: false, max_page_size: 100)

    expect(field.complexity.call({}, {}, 1)).to eq 24
    expect(field.complexity.call({}, { include_subgroups: true }, 1)).to eq 24
  end
end
