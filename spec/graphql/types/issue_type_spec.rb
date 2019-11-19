# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['Issue'] do
  it { expect(described_class).to expose_permissions_using(Types::PermissionTypes::Issue) }

  it { expect(described_class.graphql_name).to eq('Issue') }

  it { expect(described_class).to require_graphql_authorizations(:read_issue) }

  it { expect(described_class.interfaces).to include(Types::Notes::NoteableType.to_graphql) }

  it 'has specific fields' do
    fields = %i[iid title description state reference author assignees participants labels milestone due_date
                confidential discussion_locked upvotes downvotes user_notes_count web_path web_url relative_position
                subscribed time_estimate total_time_spent closed_at created_at updated_at task_completion_status]

    fields.each do |field_name|
      expect(described_class).to have_graphql_field(field_name)
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
          project(fullPath:"#{project.full_path}"){
            issue(iid:"#{issue.iid}"){
              descriptionHtml
              notes{
                edges{
                  node{
                    bodyHtml
                    author{
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
