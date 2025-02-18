# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SearchHelper, feature_category: :global_search do
  include MarkupHelper
  include BadgesHelper

  # Override simple_sanitize for our testing purposes
  def simple_sanitize(str)
    str
  end

  describe 'search_autocomplete_opts' do
    context "with no current user" do
      before do
        allow(self).to receive(:current_user).and_return(nil)
      end

      it "returns nil" do
        expect(search_autocomplete_opts("q")).to be_nil
      end
    end

    context "with a standard user" do
      let_it_be(:user) { create(:user) }

      before do
        allow(self).to receive(:current_user).and_return(user)
      end

      it "includes Help sections" do
        expect(search_autocomplete_opts("hel").size).to eq(8)
      end

      it "includes default sections" do
        expect(search_autocomplete_opts("dash").size).to eq(1)
      end

      it "does not include admin sections" do
        expect(search_autocomplete_opts("admin").size).to eq(0)
      end

      it "does not allow regular expression in search term" do
        expect(search_autocomplete_opts("(webhooks|api)").size).to eq(0)
      end

      it "includes the user's groups" do
        create(:group).add_owner(user)
        expect(search_autocomplete_opts("gro").size).to eq(1)
      end

      it "includes nested group" do
        create(:group, :nested, name: 'foo').add_owner(user)
        expect(search_autocomplete_opts('foo').size).to eq(1)
      end

      it "includes the user's projects" do
        project = create(:project, namespace: create(:namespace, owner: user))
        expect(search_autocomplete_opts(project.name).size).to eq(1)
      end

      shared_examples 'for users' do
        let_it_be(:another_user) { create(:user, name: 'Jane Doe') }
        let(:term) { 'jane' }

        it 'returns users matching the term' do
          result = search_autocomplete_opts(term)
          expect(result.size).to eq(1)
          expect(result.first[:id]).to eq(another_user.id)
        end

        context 'when current_user cannot read_users_list' do
          before do
            allow(Ability).to receive(:allowed?).and_return(true)
            allow(Ability).to receive(:allowed?).with(current_user, :read_users_list).and_return(false)
          end

          it 'returns an empty array' do
            expect(search_autocomplete_opts(term)).to eq([])
          end
        end

        describe 'permissions' do
          let(:term) { 'jane@doe' }
          let(:private_email_user) { create(:user, email: term) }
          let(:public_email_user) { create(:user, :public_email, email: term) }
          let(:banned_user) { create(:user, :banned, email: term) }
          let(:user_with_other_email) { create(:user, email: 'something@else') }
          let(:secondary_email) { create(:email, :confirmed, user: user_with_other_email, email: term) }
          let(:ids) { search_autocomplete_opts(term).pluck(:id) }

          context 'when current_user is an admin' do
            before do
              allow(current_user).to receive(:can_admin_all_resources?).and_return(true)
            end

            it 'includes users with matching public emails' do
              public_email_user
              expect(ids).to include(public_email_user.id)
            end

            it 'includes users in forbidden states' do
              banned_user
              expect(ids).to include(banned_user.id)
            end

            it 'includes users without matching public emails but with matching private emails' do
              private_email_user
              expect(ids).to include(private_email_user.id)
            end

            it 'includes users matching on secondary email' do
              secondary_email
              expect(ids).to include(secondary_email.user_id)
            end
          end

          context 'when current_user is not an admin' do
            before do
              allow(current_user).to receive(:can_admin_all_resources?).and_return(false)
            end

            it 'includes users with matching public emails' do
              public_email_user
              expect(ids).to include(public_email_user.id)
            end

            it 'does not include users in forbidden states' do
              banned_user
              expect(ids).not_to include(banned_user.id)
            end

            it 'does not include users without matching public emails but with matching private emails' do
              private_email_user
              expect(ids).not_to include(private_email_user.id)
            end

            it 'does not include users matching on secondary email' do
              secondary_email
              expect(ids).not_to include(secondary_email.user_id)
            end
          end
        end

        context 'with limiting' do
          let_it_be(:users) { create_list(:user, 6, name: 'Jane Doe') }

          it 'only returns the first 5 users' do
            result = search_autocomplete_opts(term)
            expect(result.size).to eq(5)
          end
        end
      end

      include_examples 'for users'

      it "includes the required project attrs" do
        project = create(:project, namespace: create(:namespace, owner: user))
        result = search_autocomplete_opts(project.name).first

        expect(result.keys).to match_array(%i[category id value label url avatar_url])
      end

      it "includes the required group attrs" do
        create(:group).add_owner(user)
        result = search_autocomplete_opts("gro").first

        expect(result.keys).to match_array(%i[category id value label url avatar_url])
      end

      context 'for recently reviewed items' do
        let(:search_term) { 'the search term' }
        let(:recent_issues) { instance_double(::Gitlab::Search::RecentIssues) }
        let(:recent_merge_requests) { instance_double(::Gitlab::Search::RecentMergeRequests) }

        let_it_be(:project1) { create(:project, namespace: user.namespace) }
        let_it_be(:project2) { create(:project) }

        it 'includes the users recently viewed issues and project with correct order', :aggregate_failures do
          project = create(:project, :with_avatar, title: 'the search term')
          project.add_developer(user)

          issue1 = create(:issue, title: 'issue 1', project: project)
          issue2 = create(:issue, title: 'issue 2', project: project2)

          expect(::Gitlab::Search::RecentIssues).to receive(:new).with(user: user).and_return(recent_issues)
          expect(recent_issues).to receive(:search).with(search_term)
            .and_return(Issue.id_in_ordered([issue1.id, issue2.id]))

          results = search_autocomplete_opts(search_term)

          expect(results.count).to eq(3)

          expect(results[0]).to include({
            category: 'Recent issues',
            id: issue1.id,
            label: 'issue 1',
            url: Gitlab::Routing.url_helpers.project_issue_path(issue1.project, issue1),
            avatar_url: project.avatar_url
          })

          expect(results[1]).to include({
            category: 'Recent issues',
            id: issue2.id,
            label: 'issue 2',
            url: Gitlab::Routing.url_helpers.project_issue_path(issue2.project, issue2),
            avatar_url: '' # This project didn't have an avatar so set this to ''
          })

          expect(results[2]).to include({
            category: 'Projects',
            id: project.id,
            label: project.full_name,
            url: Gitlab::Routing.url_helpers.project_path(project)
          })
        end

        it 'includes the users recently viewed issues with the exact same name', :aggregate_failures do
          expect(::Gitlab::Search::RecentIssues).to receive(:new).with(user: user).and_return(recent_issues)
          project3 = create(:project, :with_avatar, namespace: user.namespace)
          issue1 = create(:issue, title: 'issue same_name', project: project3)
          issue2 = create(:issue, title: 'issue same_name', project: project2)

          expect(recent_issues).to receive(:search).with(search_term)
            .and_return(Issue.id_in_ordered([issue1.id, issue2.id]))

          results = search_autocomplete_opts(search_term)

          expect(results.count).to eq(2)

          expect(results[0]).to include({
            category: 'Recent issues',
            id: issue1.id,
            label: 'issue same_name',
            url: Gitlab::Routing.url_helpers.project_issue_path(issue1.project, issue1),
            avatar_url: project3.avatar_url
          })

          expect(results[1]).to include({
            category: 'Recent issues',
            id: issue2.id,
            label: 'issue same_name',
            url: Gitlab::Routing.url_helpers.project_issue_path(issue2.project, issue2),
            avatar_url: '' # This project didn't have an avatar so set this to ''
          })
        end

        it 'includes the users recently viewed merge requests', :aggregate_failures do
          expect(::Gitlab::Search::RecentMergeRequests).to receive(:new).with(user: user)
            .and_return(recent_merge_requests)

          merge_request1 = create(:merge_request, :unique_branches,
            title: 'Merge request 1', target_project: project1, source_project: project1)
          merge_request2 = create(:merge_request, :unique_branches,
            title: 'Merge request 2', target_project: project2, source_project: project2)

          expect(recent_merge_requests).to receive(:search).with(search_term)
            .and_return(MergeRequest.id_in_ordered([merge_request1.id, merge_request2.id]))

          results = search_autocomplete_opts(search_term)

          expect(results.count).to eq(2)

          expect(results[0]).to include({
            category: 'Recent merge requests',
            id: merge_request1.id,
            label: 'Merge request 1',
            url: Gitlab::Routing.url_helpers.project_merge_request_path(merge_request1.project, merge_request1),
            avatar_url: '' # This project didn't have an avatar so set this to ''
          })

          expect(results[1]).to include({
            category: 'Recent merge requests',
            id: merge_request2.id,
            label: 'Merge request 2',
            url: Gitlab::Routing.url_helpers.project_merge_request_path(merge_request2.project, merge_request2),
            avatar_url: '' # This project didn't have an avatar so set this to ''
          })
        end

        it 'does not have an N+1 for recently viewed issues' do
          issue1 = create(:issue, title: 'issue 1', project: project1)
          issue2 = create(:issue, title: 'issue 2', project: project2)
          issue_ids = [issue1.id, issue2.id]

          allow(::Gitlab::Search::RecentIssues).to receive(:new).with(user: user).and_return(recent_issues)
          expect(recent_issues).to receive(:search).with(search_term).and_return(Issue.id_in_ordered(issue_ids))

          control = ActiveRecord::QueryRecorder.new(skip_cached: true) { search_autocomplete_opts(search_term) }

          issue_ids += create_list(:issue, 3).map(&:id)
          expect(recent_issues).to receive(:search).with(search_term).and_return(Issue.id_in_ordered(issue_ids))

          expect { search_autocomplete_opts(search_term) }.to issue_same_number_of_queries_as(control)
        end

        it 'does not have an N+1 for recently viewed merge_requests' do
          merge_request1 = create(:merge_request, :unique_branches,
            title: 'Merge request 1', target_project: project1, source_project: project1)
          merge_request2 = create(:merge_request, :unique_branches,
            title: 'Merge request 2', target_project: project2, source_project: project2)
          merge_request_ids = [merge_request1.id, merge_request2.id]

          expect(::Gitlab::Search::RecentMergeRequests).to receive(:new).with(user: user)
            .and_return(recent_merge_requests).twice
          expect(recent_merge_requests).to receive(:search).with(search_term)
            .and_return(MergeRequest.id_in_ordered(merge_request_ids))

          control = ActiveRecord::QueryRecorder.new(skip_cached: true) { search_autocomplete_opts(search_term) }

          merge_request_ids += create_list(:merge_request, 3, :unique_branches).map(&:id)
          expect(recent_merge_requests).to receive(:search).with(search_term)
            .and_return(MergeRequest.id_in_ordered(merge_request_ids))

          expect { search_autocomplete_opts(search_term) }.to issue_same_number_of_queries_as(control)
        end
      end

      it "does not include the public group" do
        group = build_stubbed(:group)
        expect(search_autocomplete_opts(group.name).size).to eq(0)
      end

      context "with a current project" do
        before do
          @project = create(:project, :repository)

          allow(self).to receive(:can?).and_return(true)
          allow(self).to receive(:can?).with(user, :read_feature_flag, @project).and_return(false)
        end

        it 'returns repository related labels based on users abilities', :aggregate_failures do
          expect(search_autocomplete_opts("Files").size).to eq(1)
          expect(search_autocomplete_opts("Commits").size).to eq(1)
          expect(search_autocomplete_opts("Network").size).to eq(1)
          expect(search_autocomplete_opts("Graph").size).to eq(1)

          allow(self).to receive(:can?).with(user, :read_code, @project).and_return(false)

          expect(search_autocomplete_opts("Files").size).to eq(0)
          expect(search_autocomplete_opts("Commits").size).to eq(0)

          allow(self).to receive(:can?).with(user, :read_repository_graphs, @project).and_return(false)

          expect(search_autocomplete_opts("Network").size).to eq(0)
          expect(search_autocomplete_opts("Graph").size).to eq(0)
        end

        context 'when user does not have access to project' do
          it 'does not include issues by iid' do
            issue = build_stubbed(:issue, project: @project)
            results = search_autocomplete_opts("\##{issue.iid}")

            expect(results.count).to eq(0)
          end
        end

        context 'when user has project access' do
          before do
            @project = create(:project, :repository, namespace: user.namespace)
            allow(self).to receive(:can?).with(user, :read_feature_flag, @project).and_return(true)
          end

          it 'includes issues by iid', :aggregate_failures do
            issue = create(:issue, project: @project, title: 'test title')
            results = search_autocomplete_opts("\##{issue.iid}")

            expect(results.count).to eq(1)

            expect(results.first).to include({
              category: 'In this project',
              id: issue.id,
              label: "test title (##{issue.iid})",
              url: ::Gitlab::Routing.url_helpers.project_issue_path(issue.project, issue),
              avatar_url: '' # project has no avatar
            })
          end
        end

        context 'with a search scope' do
          let(:term) { 'bla' }
          let(:scope) { 'project' }

          it 'returns scoped resource results' do
            expect(self).to receive(:resource_results).with(term, scope: scope).and_return([])

            search_autocomplete_opts(term, filter: :search, scope: scope)
          end
        end
      end
    end

    context 'with an admin user' do
      let(:admin) { build_stubbed(:admin) }

      before do
        allow(self).to receive(:current_user).and_return(admin)
      end

      context 'when admin mode setting is disabled', :do_not_mock_admin_mode_setting do
        it 'includes admin sections' do
          expect(search_autocomplete_opts('admin').size).to eq(1)
        end
      end

      context 'when admin mode setting is enabled' do
        context 'when in admin mode', :enable_admin_mode do
          it 'includes admin sections' do
            expect(search_autocomplete_opts('admin').size).to eq(1)
          end
        end

        context 'when not in admin mode' do
          it 'does not include admin sections' do
            expect(search_autocomplete_opts('admin').size).to eq(0)
          end
        end
      end
    end
  end

  describe 'resource_results' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:user) { create(:user, name: 'User') }
    let_it_be(:group) { create(:group, name: 'Group') }
    let_it_be(:project) { create(:project, name: 'Project') }
    let_it_be(:issue) { create(:issue, project: project) }
    let(:issue_iid) { "\##{issue.iid}" }

    before do
      allow(self).to receive(:current_user).and_return(user)
      group.add_owner(user)
      project.add_owner(user)
      @project = project
    end

    where(:term, :size, :category) do
      'g'             | 0 | 'Groups'
      'gr'            | 1 | 'Groups'
      'gro'           | 1 | 'Groups'
      'p'             | 0 | 'Projects'
      'pr'            | 1 | 'Projects'
      'pro'           | 1 | 'Projects'
      'u'             | 0 | 'Users'
      'us'            | 1 | 'Users'
      'use'           | 1 | 'Users'
      ref(:issue_iid) | 1 | 'In this project'
    end

    with_them do
      it 'returns results only if the term is more than or equal to Gitlab::Search::Params::MIN_TERM_LENGTH' do
        results = resource_results(term)

        expect(results.size).to eq(size)
        expect(results.first[:category]).to eq(category) if size == 1
      end
    end

    context 'with a search scope' do
      let(:term) { 'bla' }
      let(:scope) { 'projects' }

      it 'returns only scope-specific results' do
        expect(self).to receive(:scope_specific_results).with(term, scope).and_return([])
        expect(self).not_to receive(:groups_autocomplete)
        expect(self).not_to receive(:projects_autocomplete)
        expect(self).not_to receive(:users_autocomplete)
        expect(self).not_to receive(:issue_autocomplete)

        resource_results(term, scope: scope)
      end
    end

    context 'when global_search_users_enabled setting is disabled' do
      before do
        stub_application_setting(global_search_users_enabled: false)
      end

      it 'does not return results' do
        results = resource_results('use')

        expect(results).to be_empty
      end
    end
  end

  describe 'scope_specific_results' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:user) { create(:user, name: 'Searched') }
    let_it_be(:project) { create(:project, name: 'Searched') }
    let_it_be(:issue) { create(:issue, title: 'Searched', project: project) }

    before_all do
      project.add_developer(user)
    end

    before do
      allow(self).to receive(:current_user).and_return(user)
      allow_next_instance_of(Gitlab::Search::RecentIssues) do |recent_issues|
        allow(recent_issues).to receive(:search).and_return(Issue.id_in(issue.id))
      end
    end

    where(:scope, :category) do
      'users'    | 'Users'
      'projects' | 'Projects'
      'issues'   | 'Recent issues'
    end

    with_them do
      it 'returns results only for the specific scope' do
        results = scope_specific_results('sea', scope)
        expect(results.size).to eq(1)
        expect(results.first[:category]).to eq(category)
      end
    end

    context 'when scope is unknown' do
      it 'does not return any results' do
        expect(scope_specific_results('sea', 'other')).to eq([])
      end
    end

    context 'when global_search_users_enabled setting is disabled' do
      before do
        stub_application_setting(global_search_users_enabled: false)
      end

      it 'does not return results' do
        results = scope_specific_results('sea', 'users')

        expect(results).to be_empty
      end
    end
  end

  describe 'groups_autocomplete' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group_1) { create(:group, name: 'test 1') }
    let_it_be(:group_2) { create(:group, name: 'test 2') }
    let(:search_term) { 'test' }

    before do
      allow(self).to receive(:current_user).and_return(user)
    end

    context 'when the user does not have access to groups' do
      it 'does not return any results' do
        expect(groups_autocomplete(search_term)).to eq([])
      end
    end

    context 'when the user has access to one group' do
      before do
        group_2.add_developer(user)
      end

      it 'returns the group' do
        expect(groups_autocomplete(search_term).pluck(:id)).to eq([group_2.id])
      end

      context 'when the search term is Gitlab::Search::Params::MIN_TERM_LENGTH characters long' do
        let(:search_term) { 'te' }

        it 'returns the group' do
          expect(groups_autocomplete(search_term).pluck(:id)).to eq([group_2.id])
        end
      end
    end
  end

  describe 'projects_autocomplete' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project_1) { create(:project, name: 'test 1') }
    let_it_be(:project_2) { create(:project, name: 'test 2') }
    let(:search_term) { 'test' }

    before do
      allow(self).to receive(:current_user).and_return(user)
    end

    context 'when the user does not have access to projects' do
      it 'does not return any results' do
        expect(projects_autocomplete(search_term)).to eq([])
      end
    end

    context 'when the user has access to one project' do
      before_all do
        project_2.add_developer(user)
      end

      it 'returns the project' do
        expect(projects_autocomplete(search_term).pluck(:id)).to eq([project_2.id])
      end

      context 'when the search term is Gitlab::Search::Params::MIN_TERM_LENGTH characters long' do
        let(:search_term) { 'te' }

        it 'returns the project' do
          expect(projects_autocomplete(search_term).pluck(:id)).to eq([project_2.id])
        end
      end

      context 'when a project namespace matches the search term but the project does not' do
        let_it_be(:group) { create(:group, name: 'test group') }
        let_it_be(:project_3) { create(:project, name: 'nothing', namespace: group) }

        before do
          group.add_owner(user)
        end

        it 'returns all projects matching the term' do
          expect(projects_autocomplete(search_term).pluck(:id)).to match_array([project_2.id, project_3.id])
        end
      end

      context 'with feature flag autocomplete_projects_use_search_service disabled' do
        before do
          stub_feature_flags(autocomplete_projects_use_search_service: false)
        end

        it 'returns the project' do
          expect(projects_autocomplete(search_term).pluck(:id)).to eq([project_2.id])
        end

        context 'when the search term is Gitlab::Search::Params::MIN_TERM_LENGTH characters long' do
          let(:search_term) { 'te' }

          it 'returns the project' do
            expect(projects_autocomplete(search_term).pluck(:id)).to eq([project_2.id])
          end
        end

        context 'when a project namespace matches the search term but the project does not' do
          let_it_be(:group) { create(:group, name: 'test group') }
          let_it_be(:project_3) { create(:project, name: 'nothing', namespace: group) }

          before do
            group.add_owner(user)
          end

          it 'returns all projects matching the term' do
            expect(projects_autocomplete(search_term).pluck(:id)).to match_array([project_2.id, project_3.id])
          end
        end
      end
    end
  end

  describe 'search_entries_info' do
    using RSpec::Parameterized::TableSyntax

    where(:scope, :label) do
      'blobs'          | 'code result'
      'commits'        | 'commit'
      'issues'         | 'issue'
      'merge_requests' | 'merge request'
      'milestones'     | 'milestone'
      'notes'          | 'comment'
      'projects'       | 'project'
      'snippet_titles' | 'snippet'
      'users'          | 'user'
      'wiki_blobs'     | 'wiki result'
    end

    with_them do
      it 'uses the correct singular label' do
        collection = Kaminari.paginate_array([:foo]).page(1).per(10)

        expect(search_entries_info(collection, scope, 'foo'))
         .to eq("Showing 1 #{label} for <span>&nbsp;<code>foo</code>&nbsp;</span>")
      end

      it 'uses the correct plural label' do
        collection = Kaminari.paginate_array([:foo] * 23).page(1).per(10)

        expect(search_entries_info(collection, scope, 'foo'))
          .to eq("Showing 1 - 10 of 23 #{label.pluralize} for <span>&nbsp;<code>foo</code>&nbsp;</span>")
      end
    end

    it 'raises an error for unrecognized scopes' do
      expect do
        collection = Kaminari.paginate_array([:foo]).page(1).per(10)
        search_entries_info(collection, 'unknown', 'foo')
      end.to raise_error(RuntimeError)
    end
  end

  describe 'search_entries_empty_message' do
    let!(:group) { build(:group) }
    let!(:project) { build(:project, group: group) }

    context 'for global search' do
      let(:message) { search_entries_empty_message('projects', '<h1>foo</h1>', nil, nil) }

      it 'returns the formatted entry message' do
        expect(message).to eq("We couldn&#39;t find any projects matching <code>&lt;h1&gt;foo&lt;/h1&gt;</code>")
        expect(message).to be_html_safe
      end
    end

    context 'for group search' do
      let(:message) { search_entries_empty_message('projects', '<h1>foo</h1>', group, nil) }

      it 'returns the formatted entry message' do
        expect(message).to start_with('We couldn&#39;t find any projects matching <code>&lt;h1&gt;foo&lt;/h1&gt;</code> in group <a')
        expect(message).to be_html_safe
      end
    end

    context 'for project search' do
      let(:message) { search_entries_empty_message('projects', '<h1>foo</h1>', group, project) }

      it 'returns the formatted entry message' do
        expect(message).to start_with('We couldn&#39;t find any projects matching <code>&lt;h1&gt;foo&lt;/h1&gt;</code> in project <a')
        expect(message).to be_html_safe
      end
    end
  end

  describe 'search_filter_input_options' do
    context 'for project' do
      before do
        @project = create(:project, :repository)
      end

      it 'includes id with type' do
        expect(search_filter_input_options('type')[:id]).to eq('filtered-search-type')
      end

      it 'includes project-id' do
        expect(search_filter_input_options('')[:data]['project-id']).to eq(@project.id)
      end

      it 'includes project endpoints' do
        expect(search_filter_input_options('')[:data]['labels-endpoint']).to eq(project_labels_path(@project))
        expect(search_filter_input_options('')[:data]['milestones-endpoint']).to eq(project_milestones_path(@project))
        expect(search_filter_input_options('')[:data]['releases-endpoint']).to eq(project_releases_path(@project))
      end

      it 'includes autocomplete=off flag' do
        expect(search_filter_input_options('')[:autocomplete]).to eq('off')
      end
    end

    context 'for group' do
      before do
        @group = create(:group, name: 'group')
      end

      it 'does not includes project-id' do
        expect(search_filter_input_options('')[:data]['project-id']).to be_nil
      end

      it 'includes group endpoints' do
        expect(search_filter_input_options('')[:data]['labels-endpoint']).to eq(group_labels_path(@group))
        expect(search_filter_input_options('')[:data]['milestones-endpoint']).to eq(group_milestones_path(@group))
      end
    end

    context 'for dashboard' do
      it 'does not include group-id and project-id' do
        expect(search_filter_input_options('')[:data]['project-id']).to be_nil
        expect(search_filter_input_options('')[:data]['group-id']).to be_nil
      end

      it 'includes dashboard endpoints' do
        expect(search_filter_input_options('')[:data]['labels-endpoint']).to eq(dashboard_labels_path)
        expect(search_filter_input_options('')[:data]['milestones-endpoint']).to eq(dashboard_milestones_path)
      end
    end
  end

  describe 'search_history_storage_prefix' do
    context 'for project' do
      it 'returns project full_path' do
        @project = create(:project, :repository)

        expect(search_history_storage_prefix).to eq(@project.full_path)
      end
    end

    context 'for group' do
      it 'returns group full_path' do
        @group = create(:group, :nested, name: 'group-name')

        expect(search_history_storage_prefix).to eq(@group.full_path)
      end
    end

    context 'for dashboard' do
      it 'returns dashboard' do
        expect(search_history_storage_prefix).to eq("dashboard")
      end
    end
  end

  describe 'search_md_sanitize' do
    it 'does not do extra sql queries for partial markdown rendering' do
      @project = create(:project)

      description = FFaker::Lorem.characters(210)
      control = ActiveRecord::QueryRecorder.new(skip_cached: false) { search_md_sanitize(description) }

      issues = create_list(:issue, 4, project: @project)

      description_with_issues = "#{description} #{issues.map { |issue| "##{issue.iid}" }.join(' ')}"
      expect { search_md_sanitize(description_with_issues) }.not_to exceed_all_query_limit(control)
    end
  end

  describe 'search_filter_link' do
    it 'renders a search filter link for the current scope' do
      @scope = 'projects'
      @search_results = double

      expect(@search_results).to receive(:formatted_count).with('projects').and_return('23')

      link = search_filter_link('projects', 'Projects')

      expect(link).to have_css('li.active')
      expect(link).to have_link('Projects', href: search_path(scope: 'projects'))
      expect(link).to have_css('span.badge.badge-pill:not(.js-search-count):not(.hidden):not([data-url])', text: '23')
    end

    it 'renders a search filter link for another scope' do
      link = search_filter_link('projects', 'Projects')
      count_path = search_count_path(scope: 'projects')

      expect(link).to have_css('li:not([class="active"])')
      expect(link).to have_link('Projects', href: search_path(scope: 'projects'))
      expect(link).to have_css("span.badge.badge-pill.js-search-count.hidden[data-url='#{count_path}']", text: '')
    end

    it 'merges in the current search params and given params' do
      expect(self).to receive(:params).and_return(
        ActionController::Parameters.new(
          search: 'hello',
          scope: 'ignored',
          other_param: 'ignored'
        )
      )

      link = search_filter_link('projects', 'Projects', search: { project_id: 23 })

      expect(link).to have_link('Projects', href: search_path(scope: 'projects', search: 'hello', project_id: 23))
    end

    it 'restricts the params' do
      expect(self).to receive(:params).and_return(
        ActionController::Parameters.new(
          search: 'hello',
          unknown: 42
        )
      )

      link = search_filter_link('projects', 'Projects')

      expect(link).to have_link('Projects', href: search_path(scope: 'projects', search: 'hello'))
    end

    it 'assigns given data attributes on the list container' do
      link = search_filter_link('projects', 'Projects', data: { foo: 'bar' })

      expect(link).to have_css('li[data-foo="bar"]')
    end
  end

  describe '#repository_ref' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:project) { create(:project, :repository) }
    let(:default_branch) { project.default_branch }
    let(:params) { { repository_ref: ref, project_id: project_id } }

    subject { repository_ref(project) }

    where(:project_id, :ref, :expected_ref) do
      123 | 'ref-param' | 'ref-param'
      123 | nil         | ref(:default_branch)
      123 | 111111      | '111111'
      nil | 'ref-param' | ref(:default_branch)
    end

    with_them do
      it 'returns expected_ref' do
        expect(repository_ref(project)).to eq(expected_ref)
      end
    end
  end

  describe '#highlight_and_truncate_issuable' do
    let(:description) { 'hello world' }
    let(:issue) { create(:issue, description: description) }
    let(:user) { create(:user) }
    let(:highlight_and_truncate) { highlight_and_truncate_issuable(issue, 'test', {}) }

    before do
      allow(self).to receive(:current_user).and_return(user)
    end

    context 'when description is not present' do
      let(:description) { nil }

      it 'does nothing' do
        expect(self).not_to receive(:simple_search_highlight_and_truncate)

        highlight_and_truncate
      end
    end

    context 'when description present' do
      using RSpec::Parameterized::TableSyntax

      where(:description, :expected) do
        'test'                                                                 | '<mark>test</mark>'
        '<span style="color: blue;">this test should not be blue</span>'       | 'this <mark>test</mark> should not be blue'
        '<a href="#" onclick="alert(\'XSS\')">Click Me test</a>'               | '<a href="#">Click Me <mark>test</mark></a>'
        '<script type="text/javascript">alert(\'Another XSS\');</script> test' | ' <mark>test</mark>'
        'Lorem test ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Donec quam felis, ultricies nec, pellentesque eu, pretium quis, sem. Nulla consequat massa quis enim. Donec.' | 'Lorem <mark>test</mark> ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Don...'
        '<img src="https://random.foo.com/test.png" width="128" height="128" />some image' | 'some image'
        '<h2 data-sourcepos="11:1-11:26" dir="auto"><a id="user-content-additional-information" class="anchor" href="#additional-information" aria-hidden="true"></a>Additional information test:</h2><textarea data-update-url="/freepascal.org/fpc/source/-/issues/6163.json" dir="auto" data-testid="textarea" class="hidden js-task-list-field"></textarea>' | '<a class="anchor" href="#additional-information"></a>Additional information <mark>test</mark>:'
      end

      with_them do
        it 'sanitizes, truncates, and highlights the search term' do
          expect(highlight_and_truncate).to eq(expected)
        end
      end
    end
  end

  describe '#search_service' do
    let(:params) { { include_archived: true } }

    before do
      allow(self).to receive(:current_user).and_return(:the_current_user)
    end

    it 'instantiates a new SearchService with current_user and params' do
      expect(::SearchService).to receive(:new).with(:the_current_user, { include_archived: true })

      search_service
    end
  end

  describe '#issuable_state_to_badge_class' do
    context 'with merge request' do
      it 'returns correct badge based on status' do
        expect(issuable_state_to_badge_class(build(:merge_request, :merged))).to eq(:info)
        expect(issuable_state_to_badge_class(build(:merge_request, :closed))).to eq(:danger)
        expect(issuable_state_to_badge_class(build(:merge_request, :opened))).to eq(:success)
      end
    end

    context 'with an issue' do
      it 'returns correct badge based on status' do
        expect(issuable_state_to_badge_class(build(:issue, :closed))).to eq(:info)
        expect(issuable_state_to_badge_class(build(:issue, :opened))).to eq(:success)
      end
    end
  end

  describe '#issuable_state_text' do
    context 'with merge request' do
      it 'returns correct badge based on status' do
        expect(issuable_state_text(build(:merge_request, :merged))).to eq(_('Merged'))
        expect(issuable_state_text(build(:merge_request, :closed))).to eq(_('Closed'))
        expect(issuable_state_text(build(:merge_request, :opened))).to eq(_('Open'))
      end
    end

    context 'with an issue' do
      it 'returns correct badge based on status' do
        expect(issuable_state_text(build(:issue, :closed))).to eq(_('Closed'))
        expect(issuable_state_text(build(:issue, :opened))).to eq(_('Open'))
      end
    end
  end

  describe '#search_sort_options' do
    let(:user) { build_stubbed(:user) }

    mock_created_sort = [
      {
        title: _('Created date'),
        sortable: true,
        sortParam: {
          asc: 'created_asc',
          desc: 'created_desc'
        }
      },
      {
        title: _('Updated date'),
        sortable: true,
        sortParam: {
          asc: 'updated_asc',
          desc: 'updated_desc'
        }
      }
    ]

    before do
      allow(self).to receive(:current_user).and_return(user)
    end

    it 'returns the correct data' do
      expect(search_sort_options).to eq(mock_created_sort)
    end
  end

  describe '#header_search_context' do
    let(:user) { build_stubbed(:user) }
    let(:can_download) { false }
    let_it_be(:group) { nil }
    let_it_be(:project) { nil }
    let(:scope) { nil }
    let(:ref) { nil }
    let(:snippet) { nil }

    before do
      @project = project
      @group = group
      @ref = ref
      @snippet = snippet

      allow(self).to receive_messages(current_user: user, search_scope: scope, can?: can_download)
    end

    context 'when no group or project data' do
      it 'does not add :group, :group_metadata, or :scope to hash' do
        expect(header_search_context[:group]).to be_nil
        expect(header_search_context[:group_metadata]).to be_nil
        expect(header_search_context[:scope]).to be_nil
      end

      it 'does not add :project, :project_metadata, :code_search, or :ref' do
        expect(header_search_context[:project]).to be_nil
        expect(header_search_context[:project_metadata]).to be_nil
        expect(header_search_context[:code_search]).to be_nil
        expect(header_search_context[:ref]).to be_nil
      end
    end

    context 'when group data' do
      let_it_be(:group) { create(:group) }
      let(:group_metadata) { { issues_path: issues_group_path(group), mr_path: merge_requests_group_path(group) } }
      let(:scope) { 'issues' }

      it 'adds the :group, :group_metadata, and :scope correctly to hash' do
        expect(header_search_context[:group]).to eq({ id: group.id, name: group.name, full_name: group.full_name })
        expect(header_search_context[:group_metadata]).to eq(group_metadata)
        expect(header_search_context[:scope]).to eq(scope)
      end

      it 'does not add :project, :project_metadata, :code_search, or :ref' do
        expect(header_search_context[:project]).to be_nil
        expect(header_search_context[:project_metadata]).to be_nil
        expect(header_search_context[:code_search]).to be_nil
        expect(header_search_context[:ref]).to be_nil
      end
    end

    context 'when project data' do
      let_it_be(:project_group) { create(:group) }
      let_it_be(:project) { create(:project, group: project_group) }
      let(:project_metadata) do
        { issues_path: project_issues_path(project), mr_path: project_merge_requests_path(project) }
      end

      let(:group_metadata) do
        { issues_path: issues_group_path(project_group), mr_path: merge_requests_group_path(project_group) }
      end

      it 'adds the :group and :group-metadata from the project correctly to hash' do
        expect(header_search_context[:group])
          .to eq(id: project_group.id, name: project_group.name, full_name: project_group.full_name)
        expect(header_search_context[:group_metadata]).to eq(group_metadata)
      end

      it 'adds the :project and :project-metadata correctly to hash' do
        expect(header_search_context[:project]).to eq({ id: project.id, name: project.name })
        expect(header_search_context[:project_metadata]).to eq(project_metadata)
      end

      context 'when feature issues is not available' do
        let(:feature_available) { false }
        let(:project_metadata) { { mr_path: project_merge_requests_path(project) } }

        before do
          allow(project).to receive(:feature_available?).and_call_original
          allow(project).to receive(:feature_available?).with(:issues, current_user).and_return(feature_available)
        end

        it 'adds the :project and :project-metadata correctly to hash' do
          expect(header_search_context[:project]).to eq({ id: project.id, name: project.name })
          expect(header_search_context[:project_metadata]).to eq(project_metadata)
        end
      end

      context 'with scope' do
        let(:scope) { 'issues' }

        it 'adds :scope and false :code_search to hash' do
          expect(header_search_context[:scope]).to eq(scope)
          expect(header_search_context[:code_search]).to be(false)
        end
      end

      context 'without scope' do
        it 'adds code_search true to hash and not :scope' do
          expect(header_search_context[:scope]).to be_nil
          expect(header_search_context[:code_search]).to be(true)
        end
      end
    end

    context 'for ref data' do
      let_it_be(:project) { create(:project) }
      let(:ref) { 'test-branch' }

      context 'when user can? download project data' do
        let(:can_download) { true }

        it 'adds the :ref correctly to hash' do
          expect(header_search_context[:ref]).to eq(ref)
        end
      end

      context 'when user cannot download project data' do
        let(:can_download) { false }

        it 'does not add the :ref to hash' do
          expect(header_search_context[:ref]).to be_nil
        end
      end
    end

    context 'for snippet' do
      context 'when searching from snippets' do
        let(:snippet) { create(:project_snippet) }

        it 'adds :for_snippets true correctly to hash' do
          expect(header_search_context[:for_snippets]).to be(true)
        end
      end

      context 'when not searching from snippets' do
        it 'adds :for_snippets nil correctly to hash' do
          expect(header_search_context[:for_snippets]).to be_nil
        end
      end
    end
  end

  describe '.search_navigation_json' do
    using RSpec::Parameterized::TableSyntax

    context 'with some tab conditions set to false' do
      example_data_1 = {
        projects: { label: _("Projects"), condition: true },
        blobs: { label: _("Code"), condition: false }
      }

      example_data_2 = {
        projects: { label: _("Projects"), condition: false },
        blobs: { label: _("Code"), condition: false }
      }

      example_data_3 = {
        projects: { label: _("Projects"), condition: true },
        blobs: { label: _("Code"), condition: true },
        epics: { label: _("Epics"), condition: true }
      }

      where(:data, :matcher) do
        example_data_1 | -> { include("projects") }
        example_data_2 | -> { eq("{}") }
        example_data_3 | -> { include("projects", "blobs", "epics") }
      end

      with_them do
        it 'renders data correctly' do
          allow(self).to receive(:current_user).and_return(build(:user))
          allow_next_instance_of(Search::Navigation) do |search_nav|
            allow(search_nav).to receive(:tabs).and_return(data)
          end

          expect(search_navigation_json).to instance_exec(&matcher)
        end
      end
    end

    context 'when all options enabled' do
      before do
        allow(self).to receive(:current_user).and_return(build(:user))
        allow(search_service).to receive(:show_snippets?).and_return(true)
        allow_next_instance_of(Search::Navigation) do |search_nav|
          allow(search_nav).to receive_messages(tab_enabled_for_project?: true)
        end

        @project = nil
      end

      it 'returns items in order' do
        expect(Gitlab::Json.parse(search_navigation_json).keys)
          .to eq(%w[projects blobs issues merge_requests wiki_blobs commits notes milestones users snippet_titles])
      end
    end
  end

  describe '.search_filter_link_json' do
    using RSpec::Parameterized::TableSyntax

    context 'with data' do
      where(:scope, :label, :data, :search, :active_scope) do
        "projects"       | "Projects"                | { testid: 'projects-tab' } | nil                  | "projects"
        "snippet_titles" | "Snippets"                | nil                        | { snippets: "test" } | "code"
        "projects"       | "Projects"                | { testid: 'projects-tab' } | nil                  | "issue"
        "snippet_titles" | "Snippets"                | nil                        | { snippets: "test" } | "snippet_titles"
      end

      with_them do
        it 'converts correctly' do
          @timeout = false
          @scope = active_scope
          @search_results = double
          dummy_count = 1000
          allow(self).to receive(:search_path).with(any_args).and_return("link test")

          allow(@search_results).to receive(:formatted_count).with(scope).and_return(dummy_count)
          allow(self).to receive(:search_count_path).with(any_args).and_return("test count link")

          current_scope = scope == active_scope

          expected = {
            label: label,
            scope: scope,
            data: data,
            link: "link test",
            active: current_scope
          }

          expected[:count] = dummy_count if current_scope
          expected[:count_link] = "test count link" unless current_scope

          expect(search_filter_link_json(scope, label, data, search, nil)).to eq(expected)
        end
      end
    end
  end

  describe '#wiki_blob_link' do
    let_it_be(:project) { create :project, :wiki_repo }
    let(:wiki_blob) do
      Gitlab::Search::FoundBlob.new(path: 'test', basename: 'test', ref: 'master',
        data: 'foo', startline: 2, project: project, project_id: project.id)
    end

    it 'returns link' do
      expect(wiki_blob_link(wiki_blob)).to eq("/#{project.namespace.path}/#{project.path}/-/wikis/#{wiki_blob.path}")
    end
  end

  describe '#should_show_zoekt_results?' do
    before do
      allow(self).to receive(:current_user).and_return(nil)
    end

    it 'returns false for any scope and search type' do
      expect(should_show_zoekt_results?(:some_scope, :some_type)).to be false
    end
  end

  describe '#formatted_count' do
    context 'when @timeout is set' do
      it 'returns "0"' do
        @timeout = true
        @scope = 'projects'

        expect(formatted_count(@scope)).to eq("0")
      end
    end

    context 'when @search_results is defined' do
      it 'delegates formatted_count to @search_results' do
        @scope = 'projects'
        @search_results = double

        allow(@search_results).to receive(:formatted_count).with(@scope)
        expect(@search_results).to receive(:formatted_count).with(@scope)

        formatted_count(@scope)
      end
    end

    context 'when @search_results is not defined' do
      it 'returns "0"' do
        @scope = 'projects'
        expect(formatted_count(@scope)).to eq("0")
      end
    end
  end

  describe '#parse_navigation' do
    let(:navigation) do
      {
        projects: {
          sort: 1,
          label: "Projects",
          data: { testid: "projects-tab" },
          condition: true
        },
        blobs: {
          sort: 2,
          label: "Code",
          data: { testid: "code-tab" },
          condition: true
        },
        epics: {
          sort: 3,
          label: "Epics",
          condition: true
        },
        issues: {
          sort: 4, label: "Work items", condition: true, sub_items: {
            issue: {
              scope: "issues",
              label: "Issue",
              type: :issue,
              condition: true
            },
            incident: {
              scope: "issues",
              label: "Incident",
              type: :incident,
              condition: true
            },
            test_case: {
              scope: "issues",
              label: "Test Case",
              type: :test_case,
              condition: true
            },
            requirement: {
              scope: "issues",
              label: "Requirement",
              type: :requirement,
              condition: true
            },
            task: {
              scope: "issues",
              label: "Task",
              type: :task,
              condition: true
            },
            objective: {
              scope: "issues",
              label: "Objective",
              type: :objective,
              condition: true
            },
            key_result: {
              scope: "issues",
              label: "Key Result",
              type: :key_result,
              condition: true
            },
            epic: {
              scope: "issues",
              label: "Epic",
              type: :epic,
              condition: true
            },
            ticket: {
              scope: "issues",
              label: "Ticket",
              type: :ticket,
              condition: true
            }
          }
        },
        merge_requests: {
          sort: 5,
          label: "Merge requests",
          condition: true
        },
        wiki_blobs: {
          sort: 6,
          label: "Wiki",
          condition: true
        },
        commits: {
          sort: 7,
          label: "Commits",
          condition: true
        },
        notes: {
          sort: 8,
          label: "Comments",
          condition: true
        },
        milestones: {
          sort: 9,
          label: "Milestones",
          condition: true
        },
        users: {
          sort: 10,
          label: "Users",
          condition: true
        },
        snippet_titles: {
          sort: 11,
          label: "Snippets",
          condition: false
        }
      }
    end

    context 'with positive conditions' do
      let(:parse) { parse_navigation(navigation) }

      it 'includes items where condition is true' do
        expect(parse.keys).to include(:projects, :blobs, :epics, :issues, :merge_requests, :wiki_blobs, :commits,
          :notes, :milestones, :users)
      end

      it 'excludes items where condition is false' do
        expect(parse.keys).not_to include(:snippet_titles)
      end

      it 'includes correct data for a navigation item' do
        expect(parse[:projects]).to eq(
          scope: "projects",
          label: "Projects",
          data: { testid: "projects-tab" },
          active: false,
          count_link: "/search/count?scope=projects",
          link: "/search?scope=projects"
        )
      end

      it 'recursively includes sub_items with positive conditions' do
        expect(parse[:issues][:sub_items].keys)
          .to include(:issue, :incident, :test_case, :requirement, :task, :objective, :key_result, :epic, :ticket)
      end
    end

    context 'with negative conditions' do
      let(:parse) { parse_navigation(navigation) }

      before do
        navigation[:issues][:sub_items][:issue][:condition] = false
      end

      it 'excludes sub_items where condition is false' do
        expect(parse[:issues][:sub_items].keys).not_to include(:issue)
      end
    end
  end

  describe '#blob_data_oversize_message' do
    it 'returns the correct message for empty files' do
      expect(helper.blob_data_oversize_message).to eq('The file could not be displayed because it is empty.')
    end
  end
end
