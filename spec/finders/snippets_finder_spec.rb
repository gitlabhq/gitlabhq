# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SnippetsFinder do
  include ExternalAuthorizationServiceHelpers
  include Gitlab::Allowable

  describe '#initialize' do
    it 'raises ArgumentError when a project and author are given' do
      user = build(:user)
      project = build(:project)

      expect { described_class.new(user, author: user, project: project) }
        .to raise_error(ArgumentError)
    end
  end

  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:admin) { create(:admin) }
    let_it_be(:group) { create(:group, :public) }
    let_it_be(:project) { create(:project, :public, group: group) }

    let_it_be(:private_personal_snippet) { create(:personal_snippet, :private, author: user) }
    let_it_be(:internal_personal_snippet) { create(:personal_snippet, :internal, author: user) }
    let_it_be(:public_personal_snippet) { create(:personal_snippet, :public, author: user) }

    let_it_be(:private_project_snippet) { create(:project_snippet, :private, project: project) }
    let_it_be(:internal_project_snippet) { create(:project_snippet, :internal, project: project) }
    let_it_be(:public_project_snippet) { create(:project_snippet, :public, project: project) }

    context 'filter by scope' do
      it "returns all snippets for 'all' scope" do
        snippets = described_class.new(user, scope: :all).execute

        expect(snippets).to contain_exactly(
          private_personal_snippet, internal_personal_snippet, public_personal_snippet,
          internal_project_snippet, public_project_snippet
        )
      end

      it "returns all snippets for 'are_private' scope" do
        snippets = described_class.new(user, scope: :are_private).execute

        expect(snippets).to contain_exactly(private_personal_snippet)
      end

      it "returns all snippets for 'are_internal' scope" do
        snippets = described_class.new(user, scope: :are_internal).execute

        expect(snippets).to contain_exactly(internal_personal_snippet, internal_project_snippet)
      end

      it "returns all snippets for 'are_public' scope" do
        snippets = described_class.new(user, scope: :are_public).execute

        expect(snippets).to contain_exactly(public_personal_snippet, public_project_snippet)
      end
    end

    context 'filter by author' do
      context 'when the author is a User object' do
        it 'returns all public and internal snippets' do
          snippets = described_class.new(create(:user), author: user).execute

          expect(snippets).to contain_exactly(internal_personal_snippet, public_personal_snippet)
        end
      end

      context 'when the author is the User id' do
        it 'returns all public and internal snippets' do
          snippets = described_class.new(create(:user), author: user.id).execute

          expect(snippets).to contain_exactly(internal_personal_snippet, public_personal_snippet)
        end
      end

      it 'returns internal snippets' do
        snippets = described_class.new(user, author: user, scope: :are_internal).execute

        expect(snippets).to contain_exactly(internal_personal_snippet)
      end

      it 'returns private snippets' do
        snippets = described_class.new(user, author: user, scope: :are_private).execute

        expect(snippets).to contain_exactly(private_personal_snippet)
      end

      it 'returns public snippets' do
        snippets = described_class.new(user, author: user, scope: :are_public).execute

        expect(snippets).to contain_exactly(public_personal_snippet)
      end

      it 'returns all snippets' do
        snippets = described_class.new(user, author: user).execute

        expect(snippets).to contain_exactly(private_personal_snippet, internal_personal_snippet, public_personal_snippet)
      end

      it 'returns only public snippets if unauthenticated user' do
        snippets = described_class.new(nil, author: user).execute

        expect(snippets).to contain_exactly(public_personal_snippet)
      end

      it 'returns all personal snippets for an admin in admin mode', :enable_admin_mode do
        snippets = described_class.new(admin, author: user).execute

        expect(snippets).to contain_exactly(private_personal_snippet, internal_personal_snippet, public_personal_snippet)
      end

      it 'returns all snippets (everything) for an admin when all_available="true" passed in', :enable_admin_mode do
        snippets = described_class.new(admin, author: user, all_available: true).execute

        expect(snippets).to contain_exactly(
          private_project_snippet,
          internal_project_snippet,
          public_project_snippet,
          private_personal_snippet,
          internal_personal_snippet,
          public_personal_snippet)
      end

      it 'returns all snippets for non-admin user, even when all_available="true" passed in' do
        snippets = described_class.new(user, author: user, all_available: true).execute

        expect(snippets).to contain_exactly(private_personal_snippet, internal_personal_snippet, public_personal_snippet)
      end

      it 'returns all public and internal snippets for an admin without admin mode' do
        snippets = described_class.new(admin, author: user).execute

        expect(snippets).to contain_exactly(internal_personal_snippet, public_personal_snippet)
      end

      context 'when author is not valid' do
        it 'returns quickly' do
          finder = described_class.new(admin, author: non_existing_record_id)

          expect(finder).not_to receive(:init_collection)
          expect(Snippet).to receive(:none).and_call_original
          expect(finder.execute).to be_empty
        end
      end
    end

    context 'filter by project' do
      context 'when project is a Project object' do
        it 'returns public personal and project snippets for unauthorized user' do
          snippets = described_class.new(nil, project: project).execute

          expect(snippets).to contain_exactly(public_project_snippet)
        end
      end

      context 'when project is a Project id' do
        it 'returns public personal and project snippets for unauthorized user' do
          snippets = described_class.new(nil, project: project.id).execute

          expect(snippets).to contain_exactly(public_project_snippet)
        end
      end

      it 'returns public and internal snippets for non project members' do
        snippets = described_class.new(user, project: project).execute

        expect(snippets).to contain_exactly(internal_project_snippet, public_project_snippet)
      end

      it 'returns public snippets for non project members' do
        snippets = described_class.new(user, project: project, scope: :are_public).execute

        expect(snippets).to contain_exactly(public_project_snippet)
      end

      it 'returns internal snippets for non project members' do
        snippets = described_class.new(user, project: project, scope: :are_internal).execute

        expect(snippets).to contain_exactly(internal_project_snippet)
      end

      it 'does not return private snippets for non project members' do
        snippets = described_class.new(user, project: project, scope: :are_private).execute

        expect(snippets).to be_empty
      end

      it 'returns all snippets for project members' do
        project.add_developer(user)

        snippets = described_class.new(user, project: project).execute

        expect(snippets).to contain_exactly(private_project_snippet, internal_project_snippet, public_project_snippet)
      end

      it 'returns private snippets for project members' do
        project.add_developer(user)

        snippets = described_class.new(user, project: project, scope: :are_private).execute

        expect(snippets).to contain_exactly(private_project_snippet)
      end

      it 'returns all snippets for an admin in admin mode', :enable_admin_mode do
        snippets = described_class.new(admin, project: project).execute

        expect(snippets).to contain_exactly(private_project_snippet, internal_project_snippet, public_project_snippet)
      end

      it 'returns public and internal snippets for an admin without admin mode' do
        snippets = described_class.new(admin, project: project).execute

        expect(snippets).to contain_exactly(internal_project_snippet, public_project_snippet)
      end

      context 'filter by author' do
        let!(:other_user) { create(:user) }
        let!(:other_private_project_snippet) { create(:project_snippet, :private, project: project, author: other_user) }
        let!(:other_internal_project_snippet) { create(:project_snippet, :internal, project: project, author: other_user) }
        let!(:other_public_project_snippet) { create(:project_snippet, :public, project: project, author: other_user) }

        it 'returns all snippets for project members' do
          project.add_developer(user)

          snippets = described_class.new(user, author: other_user).execute

          expect(snippets)
            .to contain_exactly(
              other_private_project_snippet,
              other_internal_project_snippet,
              other_public_project_snippet
            )
        end
      end

      context 'when project is not valid' do
        it 'returns quickly' do
          finder = described_class.new(admin, project: non_existing_record_id)

          expect(finder).not_to receive(:init_collection)
          expect(Snippet).to receive(:none).and_call_original
          expect(finder.execute).to be_empty
        end
      end
    end

    context 'filter by snippet type' do
      context 'when filtering by only_personal snippet', :enable_admin_mode do
        let!(:admin_private_personal_snippet) { create(:personal_snippet, :private, author: admin) }
        let(:user_without_snippets) { create :user }

        it 'returns all personal snippets for the admin' do
          snippets = described_class.new(admin, only_personal: true).execute

          expect(snippets).to contain_exactly(
            admin_private_personal_snippet,
            private_personal_snippet,
            internal_personal_snippet,
            public_personal_snippet
          )
        end

        it 'returns only personal snippets visible by user' do
          snippets = described_class.new(user, only_personal: true).execute

          expect(snippets).to contain_exactly(
            private_personal_snippet,
            internal_personal_snippet,
            public_personal_snippet
          )
        end

        it 'returns only internal or public personal snippets for user without snippets' do
          snippets = described_class.new(user_without_snippets, only_personal: true).execute

          expect(snippets).to contain_exactly(internal_personal_snippet, public_personal_snippet)
        end
      end
    end

    context 'filtering by ids', :enable_admin_mode do
      it 'returns only personal snippet' do
        snippets = described_class.new(
          admin, ids: [private_personal_snippet.id,
                       internal_personal_snippet.id]
        ).execute

        expect(snippets).to contain_exactly(private_personal_snippet, internal_personal_snippet)
      end
    end

    context 'explore snippets' do
      it 'returns only public personal snippets for unauthenticated users' do
        snippets = described_class.new(nil, explore: true).execute

        expect(snippets).to contain_exactly(public_personal_snippet)
      end

      it 'also returns internal personal snippets for authenticated users' do
        snippets = described_class.new(user, explore: true).execute

        expect(snippets).to contain_exactly(
          internal_personal_snippet, public_personal_snippet
        )
      end

      it 'returns all personal snippets for admins when in admin mode', :enable_admin_mode do
        snippets = described_class.new(admin, explore: true).execute

        expect(snippets).to contain_exactly(
          private_personal_snippet, internal_personal_snippet, public_personal_snippet
        )
      end

      it 'also returns internal personal snippets for admins without admin mode' do
        snippets = described_class.new(admin, explore: true).execute

        expect(snippets).to contain_exactly(
          internal_personal_snippet, public_personal_snippet
        )
      end
    end

    context 'filtering for snippets authored by banned users', feature_category: :insider_threat do
      let_it_be(:banned_user) { create(:user, :banned) }

      let_it_be(:banned_public_personal_snippet) { create(:personal_snippet, :public, author: banned_user) }
      let_it_be(:banned_public_project_snippet) { create(:project_snippet, :public, project: project, author: banned_user) }

      it 'returns banned snippets for admins when in admin mode', :enable_admin_mode do
        snippets = described_class.new(
          admin,
          ids: [banned_public_personal_snippet.id, banned_public_project_snippet.id]
        ).execute

        expect(snippets).to contain_exactly(
          banned_public_personal_snippet, banned_public_project_snippet
        )
      end

      it 'does not return banned snippets for non-admin users' do
        snippets = described_class.new(
          user,
          ids: [banned_public_personal_snippet.id, banned_public_project_snippet.id]
        ).execute

        expect(snippets).to be_empty
      end

      context 'when hide_snippets_of_banned_users feature flag is off' do
        before do
          stub_feature_flags(hide_snippets_of_banned_users: false)
        end

        it 'returns banned snippets for non-admin users' do
          snippets = described_class.new(
            user,
            ids: [banned_public_personal_snippet.id, banned_public_project_snippet.id]
          ).execute

          expect(snippets).to contain_exactly(
            banned_public_personal_snippet, banned_public_project_snippet
          )
        end
      end
    end

    context 'when the user cannot read cross project' do
      before do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?).with(user, :read_cross_project) { false }
      end

      it 'returns only personal snippets when the user cannot read cross project' do
        expect(described_class.new(user).execute).to contain_exactly(private_personal_snippet, internal_personal_snippet, public_personal_snippet)
      end

      context 'when only project snippets are required' do
        it 'returns no records' do
          expect(described_class.new(user, only_project: true).execute).to be_empty
        end
      end
    end

    context 'when project snippets are disabled' do
      it 'returns quickly' do
        disabled_snippets_project = create(:project, :snippets_disabled)
        finder = described_class.new(user, project: disabled_snippets_project.id)

        expect(finder).not_to receive(:init_collection)
        expect(Snippet).to receive(:none).and_call_original
        expect(finder.execute).to be_empty
      end
    end

    context 'no sort param is provided', :enable_admin_mode do
      it 'returns snippets sorted by id' do
        snippets = described_class.new(admin).execute

        expect(snippets.ids).to eq(Snippet.order_id_desc.ids)
      end
    end

    context 'sort param is provided', :enable_admin_mode do
      it 'returns snippets sorted by sort param' do
        snippets = described_class.new(admin, sort: 'updated_desc').execute

        expect(snippets.ids).to eq(Snippet.order_updated_desc.ids)
      end
    end
  end

  it_behaves_like 'snippet visibility'

  context 'external authorization' do
    let(:user) { create(:user) }
    let(:project) { create(:project) }
    let!(:snippet) { create(:project_snippet, :public, project: project) }

    before do
      project.add_maintainer(user)
    end

    it_behaves_like 'a finder with external authorization service' do
      let!(:subject) { create(:project_snippet, project: project) }
      let(:project_params) { { project: project } }
    end

    it 'includes the result if the external service allows access' do
      external_service_allow_access(user, project)

      results = described_class.new(user, project: project).execute

      expect(results).to contain_exactly(snippet)
    end

    it 'does not include any results if the external service denies access' do
      external_service_deny_access(user, project)

      results = described_class.new(user, project: project).execute

      expect(results).to be_empty
    end
  end
end
