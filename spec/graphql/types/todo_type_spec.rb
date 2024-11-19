# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Todo'], feature_category: :notifications do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:author) { create(:user) }

  let(:issue) { create(:issue, project: project) }

  it 'has the correct fields' do
    expected_fields = [
      :id,
      :project,
      :group,
      :author,
      :action,
      :target,
      :target_entity,
      :target_type,
      :body,
      :state,
      :created_at,
      :note,
      :member_access_type,
      :target_url,
      :snoozed_until
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  specify { expect(described_class).to require_graphql_authorizations(:read_todo) }

  subject { GitlabSchema.execute(query, context: { current_user: current_user }).as_json }

  describe 'project field' do
    let(:todo) do
      create(
        :todo,
        user: current_user,
        project: project,
        state: :done,
        action: Todo::ASSIGNED,
        author: author,
        target: issue
      )
    end

    let(:query) do
      %(
        query {
          todo(id: "#{todo.to_global_id}") {
            project {
              id
            }
          }
        }
      )
    end

    context 'when the project is public' do
      let_it_be(:project) { create(:project, :public) }

      context 'when the user does not have access' do
        it 'returns the project' do
          expect(subject.dig('data', 'todo', 'project', 'id')).to eq(project.to_global_id.to_s)
        end
      end
    end

    context 'when the project is not public' do
      let_it_be(:project) { create(:project) }

      context 'when the user does not have access' do
        it 'returns null' do
          expect(subject.dig('data', 'todo', 'project')).to be_nil
        end
      end

      context 'when the user does have access' do
        before do
          project.add_guest(current_user)
        end

        it 'returns the project' do
          expect(subject.dig('data', 'todo', 'project', 'id')).to eq(project.to_global_id.to_s)
        end
      end
    end
  end

  describe 'group field' do
    let(:todo) do
      create(
        :todo,
        user: current_user,
        group: group,
        state: :done,
        action: Todo::MENTIONED,
        author: author,
        target: issue
      )
    end

    let(:query) do
      %(
        query {
          todo(id: "#{todo.to_global_id}") {
            group {
              id
            }
          }
        }
      )
    end

    context 'when the group is public' do
      let_it_be(:group) { create(:group, :public) }
      let_it_be(:project) { create(:project, :public, group: group) }

      context 'when the user does not have access' do
        it 'returns the group' do
          expect(subject.dig('data', 'todo', 'group', 'id')).to eq(group.to_global_id.to_s)
        end
      end
    end

    context 'when the group is not public' do
      let_it_be(:group) { create(:group) }
      let_it_be(:project) { create(:project, group: group) }

      context 'when the user does not have access' do
        it 'returns null' do
          expect(subject.dig('data', 'todo', 'group')).to be_nil
        end
      end

      context 'when the user does have access' do
        before do
          group.add_guest(current_user)
        end

        it 'returns the group' do
          expect(subject.dig('data', 'todo', 'group', 'id')).to eq(group.to_global_id.to_s)
        end
      end
    end
  end
end
