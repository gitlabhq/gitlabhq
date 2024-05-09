# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Note'], feature_category: :team_planning do
  include GraphqlHelpers

  it 'exposes the expected fields' do
    expected_fields = %i[
      author
      body
      body_html
      award_emoji
      internal
      created_at
      discussion
      id
      position
      project
      resolvable
      resolved
      resolved_at
      resolved_by
      system
      system_note_icon_name
      updated_at
      user_permissions
      url
      last_edited_at
      last_edited_by
      system_note_metadata
      max_access_level_of_author
      author_is_contributor
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  specify { expect(described_class).to expose_permissions_using(Types::PermissionTypes::Note) }
  specify { expect(described_class).to require_graphql_authorizations(:read_note) }

  context 'when system note with issue_email_participants action', feature_category: :service_desk do
    let_it_be(:user) { build_stubbed(:user) }
    let_it_be(:email) { 'user@example.com' }
    let_it_be(:note_text) { "added #{email}" }
    # Create project and issue separately because we need to public project.
    # rubocop:disable RSpec/FactoryBot/AvoidCreate -- Notes::RenderService updates #note and #cached_markdown_version
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:issue) { create(:issue, project: project) }
    let_it_be(:note) do
      create(:note, :system, project: project, noteable: issue, author: Users::Internal.support_bot, note: note_text)
    end

    let_it_be(:system_note_metadata) { create(:system_note_metadata, note: note, action: :issue_email_participants) }
    # rubocop:enable RSpec/FactoryBot/AvoidCreate

    let(:obfuscated_email) { 'us*****@e*****.c**' }

    describe '#body' do
      subject { resolve_field(:body, note, current_user: user) }

      it_behaves_like 'a note content field with obfuscated email address'
    end

    describe '#body_html' do
      subject { resolve_field(:body_html, note, current_user: user) }

      it_behaves_like 'a note content field with obfuscated email address'
    end
  end
end
