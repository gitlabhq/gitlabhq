# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Issue'] do
  specify { expect(described_class).to expose_permissions_using(Types::PermissionTypes::Issue) }

  specify { expect(described_class.graphql_name).to eq('Issue') }

  specify { expect(described_class).to require_graphql_authorizations(:read_issue) }

  specify { expect(described_class.interfaces).to include(Types::Notes::NoteableInterface) }

  specify { expect(described_class.interfaces).to include(Types::CurrentUserTodos) }

  it 'has specific fields' do
    fields = %i[id iid title description state reference author assignees updated_by participants labels milestone due_date
                confidential discussion_locked upvotes downvotes user_notes_count user_discussions_count web_path web_url relative_position
                emails_disabled subscribed time_estimate total_time_spent human_time_estimate human_total_time_spent closed_at created_at updated_at task_completion_status
                design_collection alert_management_alert severity current_user_todos moved moved_to
                create_note_email timelogs project_id]

    fields.each do |field_name|
      expect(described_class).to have_graphql_field(field_name)
    end
  end

  describe 'pagination and count' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:now) { Time.now.change(usec: 0) }
    let_it_be(:issues) { create_list(:issue, 10, project: project, created_at: now) }

    let(:count_path) { %w(data project issues count) }
    let(:page_size) { 3 }
    let(:query) do
      <<~GRAPHQL
        query project($fullPath: ID!, $first: Int, $after: String) {
          project(fullPath: $fullPath) {
            issues(first: $first, after: $after) {
              count
              edges {
                node {
                  iid
                }
              }
              pageInfo {
                endCursor
                hasNextPage
              }
            }
          }
        }
      GRAPHQL
    end

    subject do
      GitlabSchema.execute(
        query,
        context: { current_user: user },
        variables: {
          fullPath: project.full_path,
          first: page_size
        }
      ).to_h
    end

    context 'when user does not have the permission' do
      it 'returns no data' do
        allow(Ability).to receive(:allowed?).with(user, :read_project, project).and_return(false)

        expect(subject.dig(:data, :project)).to eq(nil)
      end
    end

    context 'count' do
      let(:end_cursor) { %w(data project issues pageInfo endCursor) }
      let(:issues_edges) { %w(data project issues edges) }

      it 'returns total count' do
        expect(subject.dig(*count_path)).to eq(issues.count)
      end

      it 'total count does not change between pages' do
        old_count = subject.dig(*count_path)
        new_cursor = subject.dig(*end_cursor)

        new_page = GitlabSchema.execute(
          query,
          context: { current_user: user },
          variables: {
            fullPath: project.full_path,
            first: page_size,
            after: new_cursor
          }
        ).to_h

        new_count = new_page.dig(*count_path)
        expect(old_count).to eq(new_count)
      end

      context 'pagination' do
        let(:page_size) { 9 }

        it 'returns new ids during pagination' do
          old_edges = subject.dig(*issues_edges)
          new_cursor = subject.dig(*end_cursor)

          new_edges = GitlabSchema.execute(
            query,
            context: { current_user: user },
            variables: {
              fullPath: project.full_path,
              first: page_size,
              after: new_cursor
            }
          ).to_h.dig(*issues_edges)

          expect(old_edges.count).to eq(9)
          expect(new_edges.count).to eq(1)
        end
      end
    end
  end

  describe "issue notes" do
    let(:user) { create(:user) }
    let(:project) { create(:project, :public) }
    let(:issue) { create(:issue, project: project) }
    let(:confidential_issue) { create(:issue, :confidential, project: project) }
    let(:private_note_body) { "mentioned in issue #{confidential_issue.to_reference(project)}" }
    let!(:note1) { create(:note, system: true, noteable: issue, author: user, project: project, note: private_note_body) }
    let!(:note2) { create(:note, system: true, noteable: issue, author: user, project: project, note: 'public note') }

    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            issue(iid: "#{issue.iid}") {
              descriptionHtml
              notes {
                edges {
                  node {
                    bodyHtml
                    author {
                      username
                    }
                    body
                  }
                }
              }
            }
          }
        }
      )
    end

    context 'query issue notes' do
      subject { GitlabSchema.execute(query, context: { current_user: current_user }).as_json }

      shared_examples_for 'does not include private notes' do
        it "does not return private notes" do
          notes = subject.dig("data", "project", "issue", "notes", 'edges')
          notes_body = notes.map {|n| n.dig('node', 'body')}

          expect(notes.size).to eq 1
          expect(notes_body).not_to include(private_note_body)
          expect(notes_body).to include('public note')
        end
      end

      shared_examples_for 'includes private notes' do
        it "returns all notes" do
          notes = subject.dig("data", "project", "issue", "notes", 'edges')
          notes_body = notes.map {|n| n.dig('node', 'body')}

          expect(notes.size).to eq 2
          expect(notes_body).to include(private_note_body)
          expect(notes_body).to include('public note')
        end
      end

      context 'when user signed in' do
        let(:current_user) { user }

        it_behaves_like 'does not include private notes'

        context 'when user member of the project' do
          before do
            project.add_developer(user)
          end

          it_behaves_like 'includes private notes'
        end
      end

      context 'when user is anonymous' do
        let(:current_user) { nil }

        it_behaves_like 'does not include private notes'
      end
    end
  end
end
