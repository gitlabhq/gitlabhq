# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Note'], feature_category: :team_planning do
  include GraphqlHelpers

  # rubocop:disable RSpec/FactoryBot/AvoidCreate -- we need the project and author for the test, id needed
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:user) { build_stubbed(:user) }

  let_it_be(:note_text) { 'note body content' }
  let_it_be(:note) { create(:note, note: note_text, project: project) }
  let_it_be(:email) { 'user@example.com' }
  # rubocop:enable RSpec/FactoryBot/AvoidCreate

  let(:batch_loader) { instance_double(Gitlab::Graphql::Loaders::BatchModelLoader) }
  let(:obfuscated_email) { 'us*****@e*****.c**' }

  it 'exposes the expected fields' do
    expected_fields = %i[
      author
      body
      body_html
      body_first_line_html
      award_emoji
      imported
      internal
      created_at
      discussion
      external_author
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
    let_it_be(:note_text) { "added #{email}" }
    # Create project and issue separately because we need a public project.
    # rubocop:disable RSpec/FactoryBot/AvoidCreate -- Notes::RenderService updates #note and #cached_markdown_version
    let_it_be(:issue) { create(:issue, project: project) }
    let_it_be(:note) do
      create(:note, :system, project: project, noteable: issue, author: Users::Internal.support_bot, note: note_text)
    end

    let_it_be(:system_note_metadata) { create(:system_note_metadata, note: note, action: :issue_email_participants) }
    # rubocop:enable RSpec/FactoryBot/AvoidCreate

    describe '#body' do
      subject { resolve_field(:body, note, current_user: user) }

      it_behaves_like 'a field with obfuscated email address'
    end

    describe '#body_html' do
      subject { resolve_field(:body_html, note, current_user: user) }

      it_behaves_like 'a field with obfuscated email address'
    end
  end

  context 'when note is from external author', feature_category: :service_desk do
    let(:note_text) { 'Note body from external participant' }

    let!(:note) { build(:note, note: note_text, project: project, author: Users::Internal.support_bot) }
    let!(:note_metadata) { build(:note_metadata, note: note) }

    describe '#external_author' do
      subject { resolve_field(:external_author, note, current_user: user) }

      it_behaves_like 'a field with obfuscated email address'
    end
  end

  describe '#project' do
    subject(:note_project) { resolve_field(:project, note, current_user: user) }

    it 'fetches the project' do
      expect(Gitlab::Graphql::Loaders::BatchModelLoader).to receive(:new).with(Project, project.id)
        .and_return(batch_loader)
      expect(batch_loader).to receive(:find)

      note_project
    end
  end

  describe '#author' do
    subject(:note_author) { resolve_field(:author, note, current_user: user) }

    it 'fetches the author' do
      expect(Gitlab::Graphql::Loaders::BatchModelLoader).to receive(:new).with(User, note.author.id)
        .and_return(batch_loader)
      expect(batch_loader).to receive(:find)

      note_author
    end
  end

  describe '#position' do
    subject(:note_position) { resolve_field(:position, note, current_user: user) }

    context 'when note is a diff note' do
      let(:note) { build_stubbed(:diff_note_on_commit, project: project) }

      it 'fetches the note position' do
        expect(note_position).to eq(note.position)
      end
    end

    context 'when note is a regular note with position set' do
      let(:note) { build_stubbed(:note, project: project, position: '{}') }

      it 'returns nil' do
        expect(note_position).to be_nil
      end
    end
  end

  describe '.authorization_scopes' do
    it 'allows ai_workflows scope token' do
      expect(described_class.authorization_scopes).to include(:ai_workflows)
    end
  end

  describe 'fields with :ai_workflows scope' do
    %w[author body createdAt id].each do |field_name|
      it "includes :ai_workflows scope for the #{field_name} field" do
        field = described_class.fields[field_name]
        expect(field.instance_variable_get(:@scopes)).to include(:ai_workflows)
      end
    end
  end
end
