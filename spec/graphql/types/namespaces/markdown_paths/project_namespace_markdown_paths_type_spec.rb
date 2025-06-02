# frozen_string_literal: true

require "spec_helper"

RSpec.describe Types::Namespaces::MarkdownPaths::ProjectNamespaceMarkdownPathsType, feature_category: :shared do
  include GraphqlHelpers
  using RSpec::Parameterized::TableSyntax

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
    context 'with valid autocomplete types' do
      where(:autocomplete_type, :expected_path) do
        'members' | lazy { "/#{project.full_path}/-/autocomplete_sources/members" }
        'issues' | lazy { "/#{project.full_path}/-/autocomplete_sources/issues" }
        'merge_requests' | lazy { "/#{project.full_path}/-/autocomplete_sources/merge_requests" }
        'labels' | lazy { "/#{project.full_path}/-/autocomplete_sources/labels" }
        'milestones' | lazy { "/#{project.full_path}/-/autocomplete_sources/milestones" }
        'commands' | lazy { "/#{project.full_path}/-/autocomplete_sources/commands" }
        'snippets' | lazy { "/#{project.full_path}/-/autocomplete_sources/snippets" }
        'contacts' | lazy { "/#{project.full_path}/-/autocomplete_sources/contacts" }
        'wikis' | lazy { "/#{project.full_path}/-/autocomplete_sources/wikis" }
      end

      with_them do
        context 'without additional params' do
          it 'returns the autocomplete path with type param' do
            result = resolve_field(:autocomplete_sources_path, project_namespace,
              args: {
                autocomplete_type: autocomplete_type
              },
              current_user: user)
            expect(result).to eq("#{expected_path}?type=WorkItem")
          end
        end

        context 'with iid' do
          it 'returns the autocomplete path with type_id param' do
            result = resolve_field(:autocomplete_sources_path, project_namespace,
              args: { autocomplete_type: autocomplete_type, iid: '456' }, current_user: user)
            expect(result).to eq("#{expected_path}?type=WorkItem&type_id=456")
          end
        end

        context 'with new-work-item-iid work item (iid: "new-work-item-iid" and work_item_type_id)' do
          it 'returns the autocomplete path with work_item_type_id param' do
            gid = 'gid://gitlab/WorkItems::Type/789'
            result = resolve_field(:autocomplete_sources_path, project_namespace,
              args: {
                autocomplete_type: autocomplete_type,
                iid: 'new-work-item-iid',
                work_item_type_id: gid
              }, current_user: user)
            expect(result).to eq("#{expected_path}?type=WorkItem&work_item_type_id=789")
          end
        end
      end
    end

    context 'with invalid autocomplete type' do
      it 'returns nil' do
        result = resolve_field(:autocomplete_sources_path, project_namespace, args: { autocomplete_type: 'invalid' },
          current_user: user)
        expect(result).to be_nil
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
