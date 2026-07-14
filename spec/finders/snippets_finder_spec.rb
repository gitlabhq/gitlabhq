# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SnippetsFinder do
  include ExternalAuthorizationServiceHelpers
  include Gitlab::Allowable

  let_it_be(:common_org) { create(:organization) }

  describe '#initialize' do
    it 'raises ArgumentError when a project and author are given' do
      user = build(:user)
      project = build(:project)

      expect { described_class.new(user, author: user, project: project, organization_id: common_org.id) }
        .to raise_error(ArgumentError)
    end

    it 'raises ArgumentError when organization_id is not provided' do
      user = build(:user)

      expect { described_class.new(user) }
        .to raise_error(ArgumentError, /organization_id is a required parameter/)
    end

    it 'raises ArgumentError when organization_id is nil' do
      user = build(:user)

      expect { described_class.new(user, organization_id: nil) }
        .to raise_error(ArgumentError, /organization_id is a required parameter/)
    end

    it 'does not raise when organization_id is provided' do
      user = build(:user)

      expect { described_class.new(user, organization_id: common_org.id) }.not_to raise_error
    end
  end

  describe '#execute' do
    let_it_be(:user) { create(:user, organization: common_org) }
    let_it_be(:admin) { create(:admin) }
    let_it_be(:group) { create(:group, :public, organization: common_org) }
    let_it_be(:project) { create(:project, :public, group: group) }

    let_it_be(:private_personal_snippet) { create(:personal_snippet, :private, author: user, organization: common_org) }
    let_it_be(:internal_personal_snippet) { create(:personal_snippet, :internal, author: user, organization: common_org) }
    let_it_be(:public_personal_snippet) { create(:personal_snippet, :public, author: user, organization: common_org) }

    let_it_be(:private_project_snippet) { create(:project_snippet, :private, project: project) }
    let_it_be(:internal_project_snippet) { create(:project_snippet, :internal, project: project) }
    let_it_be(:public_project_snippet) { create(:project_snippet, :public, project: project) }

    let(:current_user) { user }
    let(:base_params) { { organization_id: common_org.id } }
    let(:params) { base_params }
    let(:finder) { described_class.new(current_user, **params) }

    subject(:snippets) { finder.execute }

    context 'filter by scope' do
      context "with 'all' scope" do
        let(:params) { base_params.merge(scope: :all) }

        it 'returns all snippets' do
          expect(snippets).to contain_exactly(
            private_personal_snippet, internal_personal_snippet, public_personal_snippet,
            internal_project_snippet, public_project_snippet
          )
        end
      end

      context "with 'are_private' scope" do
        let(:params) { base_params.merge(scope: :are_private) }

        it 'returns private snippets' do
          expect(snippets).to contain_exactly(private_personal_snippet)
        end
      end

      context "with 'are_internal' scope" do
        let(:params) { base_params.merge(scope: :are_internal) }

        it 'returns internal snippets' do
          expect(snippets).to contain_exactly(internal_personal_snippet, internal_project_snippet)
        end
      end

      context "with 'are_public' scope" do
        let(:params) { base_params.merge(scope: :are_public) }

        it 'returns public snippets' do
          expect(snippets).to contain_exactly(public_personal_snippet, public_project_snippet)
        end
      end
    end

    context 'filter by author' do
      context 'when the author is a User object' do
        let(:current_user) { create(:user) }
        let(:params) { base_params.merge(author: user) }

        it 'returns all public and internal snippets' do
          expect(snippets).to contain_exactly(internal_personal_snippet, public_personal_snippet)
        end
      end

      context 'when the author is the User id' do
        let(:current_user) { create(:user) }
        let(:params) { base_params.merge(author: user.id) }

        it 'returns all public and internal snippets' do
          expect(snippets).to contain_exactly(internal_personal_snippet, public_personal_snippet)
        end
      end

      context 'with are_internal scope' do
        let(:params) { base_params.merge(author: user, scope: :are_internal) }

        it 'returns internal snippets' do
          expect(snippets).to contain_exactly(internal_personal_snippet)
        end
      end

      context 'with are_private scope' do
        let(:params) { base_params.merge(author: user, scope: :are_private) }

        it 'returns private snippets' do
          expect(snippets).to contain_exactly(private_personal_snippet)
        end
      end

      context 'with are_public scope' do
        let(:params) { base_params.merge(author: user, scope: :are_public) }

        it 'returns public snippets' do
          expect(snippets).to contain_exactly(public_personal_snippet)
        end
      end

      context 'without scope' do
        let(:params) { base_params.merge(author: user) }

        it 'returns all snippets' do
          expect(snippets).to contain_exactly(private_personal_snippet, internal_personal_snippet, public_personal_snippet)
        end
      end

      context 'with an unauthenticated user' do
        let(:current_user) { nil }
        let(:params) { base_params.merge(author: user) }

        it 'returns only public snippets' do
          expect(snippets).to contain_exactly(public_personal_snippet)
        end
      end

      context 'with an admin in admin mode', :enable_admin_mode do
        let(:current_user) { admin }
        let(:params) { base_params.merge(author: user) }

        it 'returns all personal snippets' do
          expect(snippets).to contain_exactly(private_personal_snippet, internal_personal_snippet, public_personal_snippet)
        end
      end

      context 'with an admin and all_available in admin mode', :enable_admin_mode do
        let(:current_user) { admin }
        let(:params) { base_params.merge(author: user, all_available: true) }

        it 'returns all snippets (everything)' do
          expect(snippets).to contain_exactly(
            private_project_snippet,
            internal_project_snippet,
            public_project_snippet,
            private_personal_snippet,
            internal_personal_snippet,
            public_personal_snippet
          )
        end
      end

      context 'with a non-admin user and all_available' do
        let(:params) { base_params.merge(author: user, all_available: true) }

        it 'returns all snippets for non-admin user, even when all_available="true" passed in' do
          expect(snippets).to contain_exactly(private_personal_snippet, internal_personal_snippet, public_personal_snippet)
        end
      end

      context 'with an admin without admin mode' do
        let(:current_user) { admin }
        let(:params) { base_params.merge(author: user) }

        it 'returns all public and internal snippets' do
          expect(snippets).to contain_exactly(internal_personal_snippet, public_personal_snippet)
        end
      end

      context 'when author is not valid' do
        let(:current_user) { admin }
        let(:params) { base_params.merge(author: non_existing_record_id) }

        it 'returns quickly' do
          expect(finder).not_to receive(:init_collection)
          expect(Snippet).to receive(:none).and_call_original
          expect(snippets).to be_empty
        end
      end
    end

    context 'filter by project' do
      context 'when project is a Project object' do
        let(:current_user) { nil }
        let(:params) { base_params.merge(project: project) }

        it 'returns public personal and project snippets for unauthorized user' do
          expect(snippets).to contain_exactly(public_project_snippet)
        end
      end

      context 'when project is a Project id' do
        let(:current_user) { nil }
        let(:params) { base_params.merge(project: project.id) }

        it 'returns public personal and project snippets for unauthorized user' do
          expect(snippets).to contain_exactly(public_project_snippet)
        end
      end

      context 'with non project members' do
        let(:params) { base_params.merge(project: project) }

        it 'returns public and internal snippets' do
          expect(snippets).to contain_exactly(internal_project_snippet, public_project_snippet)
        end
      end

      context 'with non project members and are_public scope' do
        let(:params) { base_params.merge(project: project, scope: :are_public) }

        it 'returns public snippets' do
          expect(snippets).to contain_exactly(public_project_snippet)
        end
      end

      context 'with non project members and are_internal scope' do
        let(:params) { base_params.merge(project: project, scope: :are_internal) }

        it 'returns internal snippets' do
          expect(snippets).to contain_exactly(internal_project_snippet)
        end
      end

      context 'with non project members and are_private scope' do
        let(:params) { base_params.merge(project: project, scope: :are_private) }

        it 'does not return private snippets' do
          expect(snippets).to be_empty
        end
      end

      context 'with project members' do
        let(:params) { base_params.merge(project: project) }

        before_all do
          project.add_developer(user)
        end

        it 'returns all snippets' do
          expect(snippets).to contain_exactly(private_project_snippet, internal_project_snippet, public_project_snippet)
        end
      end

      context 'with project members and are_private scope' do
        let(:params) { base_params.merge(project: project, scope: :are_private) }

        before_all do
          project.add_developer(user)
        end

        it 'returns private snippets' do
          expect(snippets).to contain_exactly(private_project_snippet)
        end
      end

      context 'with an admin in admin mode', :enable_admin_mode do
        let(:current_user) { admin }
        let(:params) { base_params.merge(project: project) }

        it 'returns all snippets' do
          expect(snippets).to contain_exactly(private_project_snippet, internal_project_snippet, public_project_snippet)
        end
      end

      context 'with an admin without admin mode' do
        let(:current_user) { admin }
        let(:params) { base_params.merge(project: project) }

        it 'returns public and internal snippets' do
          expect(snippets).to contain_exactly(internal_project_snippet, public_project_snippet)
        end
      end

      context 'filter by author' do
        let_it_be(:other_user) { create(:user) }
        let_it_be(:other_private_project_snippet) { create(:project_snippet, :private, project: project, author: other_user) }
        let_it_be(:other_internal_project_snippet) { create(:project_snippet, :internal, project: project, author: other_user) }
        let_it_be(:other_public_project_snippet) { create(:project_snippet, :public, project: project, author: other_user) }

        let(:params) { base_params.merge(author: other_user) }

        before_all do
          project.add_developer(user)
        end

        it 'returns all snippets for project members' do
          expect(snippets).to contain_exactly(
            other_private_project_snippet,
            other_internal_project_snippet,
            other_public_project_snippet
          )
        end
      end

      context 'when project is not valid' do
        let(:current_user) { admin }
        let(:params) { base_params.merge(project: non_existing_record_id) }

        it 'returns quickly' do
          expect(finder).not_to receive(:init_collection)
          expect(Snippet).to receive(:none).and_call_original
          expect(snippets).to be_empty
        end
      end
    end

    context 'filter by snippet type' do
      context 'when filtering by only_personal snippet', :enable_admin_mode do
        let_it_be(:admin_private_personal_snippet) { create(:personal_snippet, :private, author: admin, organization: common_org) }

        let(:params) { base_params.merge(only_personal: true) }

        context 'with the admin' do
          let(:current_user) { admin }

          it 'returns all personal snippets for the admin' do
            expect(snippets).to contain_exactly(
              admin_private_personal_snippet,
              private_personal_snippet,
              internal_personal_snippet,
              public_personal_snippet
            )
          end
        end

        context 'with a user that has snippets' do
          it 'returns only personal snippets visible by user' do
            expect(snippets).to contain_exactly(
              private_personal_snippet,
              internal_personal_snippet,
              public_personal_snippet
            )
          end
        end

        context 'with a user without snippets' do
          let(:current_user) { create(:user) }

          it 'returns only internal or public personal snippets for user without snippets' do
            expect(snippets).to contain_exactly(internal_personal_snippet, public_personal_snippet)
          end
        end
      end
    end

    context 'filtering by ids', :enable_admin_mode do
      let(:current_user) { admin }
      let(:params) { base_params.merge(ids: [private_personal_snippet.id, internal_personal_snippet.id]) }

      it 'returns only personal snippet' do
        expect(snippets).to contain_exactly(private_personal_snippet, internal_personal_snippet)
      end
    end

    context 'explore snippets' do
      let(:params) { base_params.merge(explore: true) }

      context 'with an unauthenticated user' do
        let(:current_user) { nil }

        it 'returns only public personal snippets' do
          expect(snippets).to contain_exactly(public_personal_snippet)
        end
      end

      context 'with an authenticated user' do
        it 'also returns internal personal snippets' do
          expect(snippets).to contain_exactly(
            internal_personal_snippet, public_personal_snippet
          )
        end
      end

      context 'with an admin in admin mode', :enable_admin_mode do
        let(:current_user) { admin }

        it 'returns all personal snippets' do
          expect(snippets).to contain_exactly(
            private_personal_snippet, internal_personal_snippet, public_personal_snippet
          )
        end
      end

      context 'with an admin without admin mode' do
        let(:current_user) { admin }

        it 'also returns internal personal snippets' do
          expect(snippets).to contain_exactly(
            internal_personal_snippet, public_personal_snippet
          )
        end
      end
    end

    context 'filtering for snippets authored by banned users', feature_category: :insider_threat do
      let_it_be(:banned_user) { create(:user, :banned) }

      let_it_be(:banned_public_personal_snippet) { create(:personal_snippet, :public, author: banned_user, organization: common_org) }
      let_it_be(:banned_public_project_snippet) { create(:project_snippet, :public, project: project, author: banned_user) }

      let(:params) { base_params.merge(ids: [banned_public_personal_snippet.id, banned_public_project_snippet.id]) }

      context 'with an admin in admin mode', :enable_admin_mode do
        let(:current_user) { admin }

        it 'returns banned snippets' do
          expect(snippets).to contain_exactly(
            banned_public_personal_snippet, banned_public_project_snippet
          )
        end
      end

      context 'with a non-admin user' do
        it 'does not return banned snippets' do
          expect(snippets).to be_empty
        end
      end
    end

    context 'when the user cannot read cross project' do
      before do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?).with(user, :read_cross_project) { false }
      end

      it 'returns only personal snippets when the user cannot read cross project' do
        expect(snippets).to contain_exactly(private_personal_snippet, internal_personal_snippet, public_personal_snippet)
      end

      context 'when only project snippets are required' do
        let(:params) { base_params.merge(only_project: true) }

        it 'returns no records' do
          expect(snippets).to be_empty
        end
      end

      context 'when a project is provided' do
        let(:params) { base_params.merge(project: project) }

        before_all do
          project.add_developer(user)
        end

        it 'returns project snippets even without read_cross_project' do
          expect(snippets).to contain_exactly(
            private_project_snippet,
            internal_project_snippet,
            public_project_snippet
          )
        end
      end
    end

    context 'when project snippets are disabled' do
      let_it_be(:disabled_snippets_project) { create(:project, :snippets_disabled) }

      let(:params) { base_params.merge(project: disabled_snippets_project.id) }

      it 'returns quickly' do
        expect(finder).not_to receive(:init_collection)
        expect(Snippet).to receive(:none).and_call_original
        expect(snippets).to be_empty
      end
    end

    context 'no sort param is provided', :enable_admin_mode do
      let(:current_user) { admin }

      it 'returns snippets sorted by id' do
        expect(snippets.ids).to eq(Snippet.order_id_desc.ids)
      end
    end

    context 'sort param is provided', :enable_admin_mode do
      let(:current_user) { admin }
      let(:params) { base_params.merge(sort: 'updated_desc') }

      it 'returns snippets sorted by sort param' do
        expect(snippets.ids).to eq(Snippet.order_updated_desc.ids)
      end
    end

    # rubocop:disable RSpec/MultipleMemoizedHelpers -- Cross-org isolation needs fixtures for two organizations
    context 'organization isolation' do
      let_it_be(:org1) { create(:organization) }
      let_it_be(:org2) { create(:organization) }
      let_it_be(:user_org1) { create(:user, organization: org1) }
      let_it_be(:user_org2) { create(:user, organization: org2) }
      let_it_be(:snippet_org1_private) { create(:personal_snippet, :private, author: user_org1, organization: org1) }
      let_it_be(:snippet_org1_public) { create(:personal_snippet, :public, author: user_org1, organization: org1) }
      let_it_be(:snippet_org2_private) { create(:personal_snippet, :private, author: user_org2, organization: org2) }
      let_it_be(:snippet_org2_public) { create(:personal_snippet, :public, author: user_org2, organization: org2) }

      # Project snippets to verify that the project path bypasses org filtering
      let_it_be(:project_org1) { create(:project, :public, organization: org1) }
      let_it_be(:project_org2) { create(:project, :public, organization: org2) }
      let_it_be(:project_snippet_org1) { create(:project_snippet, :public, project: project_org1) }
      let_it_be(:project_snippet_org2) { create(:project_snippet, :public, project: project_org2) }

      # A user who is a member of multiple organizations, with a personal snippet in each.
      let_it_be(:multi_org_user) { create(:user, organization: org1) }
      let_it_be(:multi_snippet_org1) { create(:personal_snippet, :private, author: multi_org_user, organization: org1) }
      let_it_be(:multi_snippet_org2) { create(:personal_snippet, :private, author: multi_org_user, organization: org2) }

      let(:current_user) { user_org1 }
      let(:base_params) { { organization_id: org1.id } }

      before_all do
        project_org1.add_developer(multi_org_user)
        project_org2.add_developer(multi_org_user)
      end

      context 'when isolation is enabled (isolated organization)' do
        before do
          allow(::Gitlab::Organizations::Isolation).to receive(:enabled?).and_return(true)
        end

        context 'when filtering for personal snippets only' do
          let(:params) { base_params.merge(only_personal: true) }

          it 'returns only snippets from the specified organization', :aggregate_failures do
            expect(snippets).to contain_exactly(snippet_org1_private, snippet_org1_public)
            expect(snippets).not_to include(snippet_org2_private, snippet_org2_public)
          end
        end

        context 'when the user belongs to multiple organizations' do
          let(:current_user) { multi_org_user }
          let(:params) { base_params.merge(only_personal: true) }

          it 'does not leak snippets from other organizations the user belongs to', :aggregate_failures do
            expect(snippets).to include(multi_snippet_org1)
            expect(snippets).not_to include(multi_snippet_org2, snippet_org2_private, snippet_org2_public)
          end
        end

        context 'when exploring snippets' do
          let(:params) { base_params.merge(explore: true) }

          it 'returns only public snippets from the specified organization' do
            expect(snippets).to contain_exactly(snippet_org1_public)
          end
        end

        context 'when including project snippets' do
          let(:params) { base_params.merge(scope: :all) }

          it 'returns only snippets from the specified organization', :aggregate_failures do
            expect(snippets).to include(snippet_org1_private, snippet_org1_public, project_snippet_org1)
            expect(snippets).not_to include(snippet_org2_private, snippet_org2_public, project_snippet_org2)
          end
        end

        context 'when user is admin in admin mode', :enable_admin_mode do
          let(:current_user) { admin }
          let(:params) { base_params.merge(all_available: true) }

          it 'returns all snippets across organizations with all_available flag' do
            expect(snippets).to include(snippet_org1_private, snippet_org1_public, snippet_org2_private, snippet_org2_public)
          end
        end
      end

      context 'when isolation is disabled (non-isolated/encapsulated organization)' do
        before do
          allow(::Gitlab::Organizations::Isolation).to receive(:enabled?).and_return(false)
        end

        context 'when filtering by author across organizations' do
          let(:current_user) { multi_org_user }
          let(:params) { base_params.merge(author: multi_org_user, only_personal: true) }

          it "returns the author's personal snippets across all organizations", :aggregate_failures do
            expect(snippets).to contain_exactly(multi_snippet_org1, multi_snippet_org2)
            expect(snippets).not_to include(snippet_org1_private, snippet_org2_private)
          end
        end

        context 'when no scope restricts the result' do
          let(:current_user) { multi_org_user }
          let(:params) { base_params }

          it 'does not apply the organization filter, returning snippets from multiple organizations' do
            expect(snippets).to include(project_snippet_org1, project_snippet_org2)
          end
        end

        context 'when filtering for personal snippets only' do
          let(:current_user) { multi_org_user }
          let(:params) { base_params.merge(only_personal: true) }

          it 'returns public personal snippets from all organizations' do
            expect(snippets).to include(snippet_org1_public, snippet_org2_public)
          end
        end

        context 'when user is admin in admin mode', :enable_admin_mode do
          let(:current_user) { admin }
          let(:params) { base_params.merge(all_available: true) }

          it 'returns all snippets across organizations with all_available flag' do
            expect(snippets).to include(snippet_org1_private, snippet_org1_public, snippet_org2_private, snippet_org2_public)
          end
        end
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers
  end

  it_behaves_like 'snippet visibility'

  context 'external authorization' do
    let_it_be(:org) { create(:organization) }
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, organization: org, maintainers: user) }
    let_it_be(:snippet) { create(:project_snippet, :public, project: project) }

    let(:current_user) { user }
    let(:base_params) { { organization_id: org.id } }
    let(:params) { base_params.merge(project: project) }
    let(:finder) { described_class.new(current_user, **params) }

    subject(:search) { finder.execute }

    it_behaves_like 'a finder with external authorization service' do
      let(:org) { create(:organization) }
      let(:project) { create(:project, organization: org) }
      let!(:subject) { create(:project_snippet, project: project) }
      let(:execute) { described_class.new(user, organization_id: org.id).execute }
      let(:project_execute) { described_class.new(user, project: project, organization_id: org.id).execute }
    end

    context 'when the external service allows access' do
      before do
        external_service_allow_access(user, project)
      end

      it 'includes the result' do
        expect(search).to contain_exactly(snippet)
      end
    end

    context 'when the external service denies access' do
      before do
        external_service_deny_access(user, project)
      end

      it 'does not include any results' do
        expect(search).to be_empty
      end
    end
  end
end
