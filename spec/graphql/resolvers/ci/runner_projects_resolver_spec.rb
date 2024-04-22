# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::RunnerProjectsResolver, feature_category: :fleet_visibility do
  include GraphqlHelpers

  let_it_be(:project1) { create(:project, description: 'Project1.1') }
  let_it_be(:project2) { create(:project, description: 'Project1.2') }
  let_it_be(:project3) { create(:project, description: 'Project2.1') }
  let_it_be(:runner) { create(:ci_runner, :project, projects: [project1, project2, project3]) }

  let(:args) { {} }

  subject { resolve_projects(args) }

  describe '#resolve' do
    context 'with authorized user', :enable_admin_mode do
      let_it_be(:current_user) { create(:user, :admin) }

      context 'with search argument' do
        let(:args) { { search: 'Project1.' } }

        it 'returns a lazy value with projects containing the specified prefix' do
          expect(subject).to be_a(GraphQL::Execution::Lazy)
          expect(subject.value).to contain_exactly(project1, project2)
        end
      end

      context 'with sort argument' do
        let(:args) { { sort: sort } }

        context 'when :id_asc' do
          let(:sort) { :id_asc }

          it 'returns a lazy value with projects sorted by :id_asc' do
            expect(subject).to be_a(GraphQL::Execution::Lazy)
            expect(subject.value.items).to eq([project1, project2, project3])
          end
        end

        context 'when :id_desc' do
          let(:sort) { :id_desc }

          it 'returns a lazy value with projects sorted by :id_desc' do
            expect(subject).to be_a(GraphQL::Execution::Lazy)
            expect(subject.value.items).to eq([project3, project2, project1])
          end
        end
      end

      context 'with supported arguments' do
        let(:args) { { membership: true, search_namespaces: true, topics: %w[xyz] } }

        it 'creates ProjectsFinder with expected arguments' do
          expect(ProjectsFinder).to receive(:new).with(
            a_hash_including(
              params: a_hash_including(
                non_public: true,
                search_namespaces: true,
                topic: %w[xyz]
              )
            )
          ).and_call_original

          expect(subject).to be_a(GraphQL::Execution::Lazy)
          subject.value
        end
      end

      context 'without arguments' do
        it 'returns a lazy value with all projects sorted by :id_desc' do
          expect(subject).to be_a(GraphQL::Execution::Lazy)
          expect(subject.value.items).to eq([project3, project2, project1])
        end
      end
    end

    context 'with unauthorized user' do
      let_it_be(:current_user) { create(:user) }

      it { is_expected.to be_nil }
    end
  end

  private

  def resolve_projects(args = {}, context = { current_user: current_user })
    resolve(described_class, obj: runner, args: args, ctx: context)
  end
end
