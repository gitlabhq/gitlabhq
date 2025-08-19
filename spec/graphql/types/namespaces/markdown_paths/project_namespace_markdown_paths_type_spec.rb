# frozen_string_literal: true

require "spec_helper"

RSpec.describe Types::Namespaces::MarkdownPaths::ProjectNamespaceMarkdownPathsType, feature_category: :shared do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:project_namespace) { project.project_namespace }

  describe '#uploads_path' do
    it 'returns the project uploads path' do
      expect(resolve_field(:uploads_path, project_namespace,
        current_user: user)).to eq("/#{project.full_path}/uploads")
    end
  end

  describe '#markdown_preview_path' do
    context 'without iid' do
      it 'returns the basic preview markdown path' do
        expect(resolve_field(:markdown_preview_path, project_namespace,
          current_user: user)).to eq("/#{project.full_path}/-/preview_markdown?target_type=WorkItem")
      end
    end

    context 'with iid' do
      it 'returns the preview markdown path with target_id' do
        expect(resolve_field(:markdown_preview_path, project_namespace, args: { iid: '123' }, current_user: user))
          .to eq("/#{project.full_path}/-/preview_markdown?target_id=123&target_type=WorkItem")
      end
    end
  end

  describe '#autocomplete_sources_path' do
    context 'without additional params' do
      it 'returns all autocomplete paths with type param' do
        result = resolve_field(:autocomplete_sources_path, project_namespace, current_user: user)

        expect(result).to be_a(Hash)
        expect(result).to include(
          members: "/#{project.full_path}/-/autocomplete_sources/members?type=WorkItem",
          issues: "/#{project.full_path}/-/autocomplete_sources/issues?type=WorkItem",
          merge_requests: "/#{project.full_path}/-/autocomplete_sources/merge_requests?type=WorkItem",
          labels: "/#{project.full_path}/-/autocomplete_sources/labels?type=WorkItem",
          milestones: "/#{project.full_path}/-/autocomplete_sources/milestones?type=WorkItem",
          commands: "/#{project.full_path}/-/autocomplete_sources/commands?type=WorkItem",
          snippets: "/#{project.full_path}/-/autocomplete_sources/snippets?type=WorkItem",
          contacts: "/#{project.full_path}/-/autocomplete_sources/contacts?type=WorkItem",
          wikis: "/#{project.full_path}/-/autocomplete_sources/wikis?type=WorkItem"
        )
      end
    end

    context 'with iid' do
      it 'returns all autocomplete paths with type_id param' do
        result = resolve_field(:autocomplete_sources_path, project_namespace, args: { iid: '456' }, current_user: user)

        expect(result).to be_a(Hash)
        expect(result).to include(
          members: "/#{project.full_path}/-/autocomplete_sources/members?type=WorkItem&type_id=456",
          issues: "/#{project.full_path}/-/autocomplete_sources/issues?type=WorkItem&type_id=456",
          merge_requests: "/#{project.full_path}/-/autocomplete_sources/merge_requests?type=WorkItem&type_id=456",
          labels: "/#{project.full_path}/-/autocomplete_sources/labels?type=WorkItem&type_id=456",
          milestones: "/#{project.full_path}/-/autocomplete_sources/milestones?type=WorkItem&type_id=456",
          commands: "/#{project.full_path}/-/autocomplete_sources/commands?type=WorkItem&type_id=456",
          snippets: "/#{project.full_path}/-/autocomplete_sources/snippets?type=WorkItem&type_id=456",
          contacts: "/#{project.full_path}/-/autocomplete_sources/contacts?type=WorkItem&type_id=456",
          wikis: "/#{project.full_path}/-/autocomplete_sources/wikis?type=WorkItem&type_id=456"
        )
      end
    end

    context 'with new-work-item-iid and work_item_type_id' do
      it 'returns all autocomplete paths with work_item_type_id param' do
        gid = 'gid://gitlab/WorkItems::Type/789'
        result = resolve_field(:autocomplete_sources_path, project_namespace,
          args: { iid: 'new-work-item-iid', work_item_type_id: gid }, current_user: user)

        expect(result).to be_a(Hash)
        expect(result).to include(
          members: "/#{project.full_path}/-/autocomplete_sources/members?type=WorkItem&work_item_type_id=789",
          issues: "/#{project.full_path}/-/autocomplete_sources/issues?type=WorkItem&work_item_type_id=789",
          merge_requests: "/#{project.full_path}/-/autocomplete_sources/merge_requests" \
            "?type=WorkItem&work_item_type_id=789",
          labels: "/#{project.full_path}/-/autocomplete_sources/labels?type=WorkItem&work_item_type_id=789",
          milestones: "/#{project.full_path}/-/autocomplete_sources/milestones?type=WorkItem&work_item_type_id=789",
          commands: "/#{project.full_path}/-/autocomplete_sources/commands?type=WorkItem&work_item_type_id=789",
          snippets: "/#{project.full_path}/-/autocomplete_sources/snippets?type=WorkItem&work_item_type_id=789",
          contacts: "/#{project.full_path}/-/autocomplete_sources/contacts?type=WorkItem&work_item_type_id=789",
          wikis: "/#{project.full_path}/-/autocomplete_sources/wikis?type=WorkItem&work_item_type_id=789"
        )
      end
    end
  end

  context 'when project is private' do
    let_it_be(:private_project) { create(:project, :private) }
    let_it_be(:private_project_namespace) { private_project.project_namespace }

    context 'when user is not a member' do
      it 'still returns paths' do
        expect(resolve_field(:uploads_path, private_project_namespace,
          current_user: user)).to eq("/#{private_project.full_path}/uploads")
      end
    end

    context 'when user is a member' do
      before_all do
        private_project.add_developer(user)
      end

      it 'returns paths' do
        expect(resolve_field(:uploads_path, private_project_namespace,
          current_user: user)).to eq("/#{private_project.full_path}/uploads")
      end
    end
  end
end
