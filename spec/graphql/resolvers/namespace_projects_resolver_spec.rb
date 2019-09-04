# frozen_string_literal: true

require 'spec_helper'

describe Resolvers::NamespaceProjectsResolver do
  include GraphqlHelpers

  let(:current_user) { create(:user) }

  context "with a group" do
    let(:group) { create(:group) }
    let(:namespace) { group }
    let(:project1) { create(:project, namespace: namespace) }
    let(:project2) { create(:project, namespace: namespace) }
    let(:nested_group) { create(:group, parent: group) }
    let(:nested_project) { create(:project, group: nested_group) }

    before do
      project1.add_developer(current_user)
      project2.add_developer(current_user)
      nested_project.add_developer(current_user)
    end

    describe '#resolve' do
      it 'finds all projects' do
        expect(resolve_projects).to contain_exactly(project1, project2)
      end

      it 'finds all projects including the subgroups' do
        expect(resolve_projects(include_subgroups: true)).to contain_exactly(project1, project2, nested_project)
      end

      context 'with an user namespace' do
        let(:namespace) { current_user.namespace }

        it 'finds all projects' do
          expect(resolve_projects).to contain_exactly(project1, project2)
        end

        it 'finds all projects including the subgroups' do
          expect(resolve_projects(include_subgroups: true)).to contain_exactly(project1, project2)
        end
      end
    end
  end

  context "when passing a non existent, batch loaded namespace" do
    let(:namespace) do
      BatchLoader::GraphQL.for("non-existent-path").batch do |_fake_paths, loader, _|
        loader.call("non-existent-path", nil)
      end
    end

    it "returns nil without breaking" do
      expect(resolve_projects).to be_empty
    end
  end

  it 'has an high complexity regardless of arguments' do
    field = Types::BaseField.new(name: 'test', type: GraphQL::STRING_TYPE.connection_type, resolver_class: described_class, null: false, max_page_size: 100)

    expect(field.to_graphql.complexity.call({}, {}, 1)).to eq 24
    expect(field.to_graphql.complexity.call({}, { include_subgroups: true }, 1)).to eq 24
  end

  def resolve_projects(args = { include_subgroups: false }, context = { current_user: current_user })
    resolve(described_class, obj: namespace, args: args, ctx: context)
  end
end
