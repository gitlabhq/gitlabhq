# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ReleasesHelper, feature_category: :release_orchestration do
  describe '#illustration' do
    it 'returns the correct image path' do
      expect(helper.illustration).to match(%r{illustrations/rocket-launch-md-(\w+)\.svg})
    end
  end

  describe '#releases_help_page_path' do
    it 'returns the correct link to the help page' do
      expect(helper.releases_help_page_path).to include('user/project/releases/_index')
    end
  end

  context 'url helpers' do
    let(:project) { build(:project, namespace: create(:group)) }
    let(:release) { create(:release, project: project) }
    let(:user) { create(:user) }
    let(:can_user_create_release) { false }
    let(:common_keys) { [:project_id, :project_path, :illustration_path, :documentation_path, :atom_feed_path] }

    # rubocop: disable CodeReuse/ActiveRecord
    before do
      helper.instance_variable_set(:@project, project)
      helper.instance_variable_set(:@release, release)
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:can?)
                         .with(user, :create_release, project)
                         .and_return(can_user_create_release)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    describe '#data_for_releases_page' do
      it 'includes the required data for displaying release blocks' do
        expect(helper.data_for_releases_page.keys).to contain_exactly(*common_keys)
      end

      context 'when the user is allowed to create a new release' do
        let(:can_user_create_release) { true }

        it 'includes new_release_path' do
          expect(helper.data_for_releases_page.keys).to contain_exactly(*common_keys, :new_release_path)
        end

        it 'points new_release_path to the "New Release" page' do
          expect(helper.data_for_releases_page[:new_release_path]).to eq(new_project_release_path(project))
        end
      end

      context 'new releases redirect new milestone creation' do
        it 'redirects new_milestone_path back to the release page' do
          expect(helper.data_for_new_release_page[:new_milestone_path]).to include('redirect_path')
        end
      end
    end

    describe '#data_for_edit_release_page' do
      it 'has the needed data to display the "edit release" page' do
        keys = %i[project_id
                  group_id
                  group_milestones_available
                  project_path
                  tag_name
                  markdown_preview_path
                  markdown_docs_path
                  releases_page_path
                  release_assets_docs_path
                  manage_milestones_path
                  new_milestone_path
                  upcoming_release_docs_path
                  edit_release_docs_path
                  delete_release_docs_path]

        expect(helper.data_for_edit_release_page.keys).to match_array(keys)
      end
    end

    describe '#data_for_new_release_page' do
      it 'has the needed data to display the "new release" page' do
        keys = %i[project_id
                  group_id
                  group_milestones_available
                  project_path
                  tag_name
                  releases_page_path
                  markdown_preview_path
                  markdown_docs_path
                  release_assets_docs_path
                  manage_milestones_path
                  new_milestone_path
                  default_branch
                  upcoming_release_docs_path
                  edit_release_docs_path]

        expect(helper.data_for_new_release_page.keys).to match_array(keys)
      end
    end

    describe '#data_for_show_page' do
      let_it_be(:user) { create(:user) }
      let_it_be(:project) { create(:project, :repository) }
      let_it_be(:commit) { create(:commit, project: project, id: '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9') }
      let_it_be(:release) { create(:release, project: project, tag: 'v1.0.0', sha: commit.id) }
      let_it_be(:environment) { create(:environment, project: project) }
      let_it_be(:deployable) { create(:ci_build, user: user, project: project) }
      let_it_be(:deployment) do
        create(:deployment,
          project: project,
          environment: environment,
          deployable: deployable,
          ref: release.tag,
          sha: release.sha)
      end

      # rubocop: disable CodeReuse/ActiveRecord -- mock for can? is incorrectly flagged
      before do
        helper.instance_variable_set(:@project, project)
        helper.instance_variable_set(:@release, release)

        allow(helper).to receive(:current_user).and_return(user)
        allow(release).to receive(:related_deployments).and_return([deployment])
        allow(helper).to receive(:can?)
                          .with(user, :read_deployment, project)
                          .and_return(true)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      it 'has the needed data to display the individual "release" page' do
        keys = %i[project_id
                  project_path
                  tag_name
                  deployments]

        expect(helper.data_for_show_page.keys).to match_array(keys)
      end

      context 'deployments field' do
        context 'when user can read deployments' do
          it 'returns deployments data' do
            deployment_data = Gitlab::Json.parse(helper.data_for_show_page[:deployments]).first
            environment_url = project_environment_url(project, environment)
            deployment_url = project_environment_deployment_path(project, environment, deployment)

            expect(deployment_data['environment']['name']).to eq(environment.name)
            expect(deployment_data['environment']['url']).to eq(environment_url)

            expect(deployment_data['deployment']['id']).to eq(deployment.id)
            expect(deployment_data['deployment']['url']).to eq(deployment_url)

            expect(deployment_data['commit']['name']).to eq(project.repository.commit(release.tag).author_name)
            expect(deployment_data['commit']['sha']).to eq(project.repository.commit(release.tag).id)
            expect(deployment_data['commit']['commit_url']).to eq(project_commit_url(deployment.project, commit))
            expect(deployment_data['commit']['short_sha']).to eq(project.repository.commit(release.tag).short_id)
            expect(deployment_data['commit']['title']).to eq(project.repository.commit(release.tag).title)

            expect(deployment_data['triggerer']['name']).to eq(user.name)
            expect(deployment_data['triggerer']['avatar_url']).to eq(user.avatar_url)
            expect(deployment_data['triggerer']['web_url']).to eq(user_url(user))

            expect(deployment_data['status']).to eq(deployment.status)
            expect(deployment_data['created_at']).to be_present
            expect(deployment_data['finished_at']).to be_nil
          end
        end

        context 'when deployable is nil' do
          let_it_be(:deployment_with_user) do
            create(:deployment, environment: environment, project: project, sha: project.repository.commit.id,
              deployable: nil)
          end

          before do
            allow(release).to receive(:related_deployments).and_return([deployment_with_user])
          end

          it 'sets triggerer as nil' do
            deployment_data = Gitlab::Json.parse(helper.data_for_show_page[:deployments]).first

            expect(deployment_data['triggerer']).to be_nil
          end
        end

        context 'when user cannot read deployments' do
          # rubocop: disable CodeReuse/ActiveRecord -- mock for can? is incorrectly flagged
          before do
            allow(helper).to receive(:can?)
                              .with(user, :read_deployment, project)
                              .and_return(false)
          end
          # rubocop: enable CodeReuse/ActiveRecord

          it 'returns an empty array' do
            expect(helper.data_for_show_page[:deployments]).to eq('[]')
          end
        end
      end
    end
  end

  describe 'startup queries' do
    describe 'use_startup_query_for_index_page?' do
      it 'allows startup queries for non-paginated requests' do
        allow(helper).to receive(:params).and_return({ unrelated_query_param: 'value' })

        expect(helper.use_startup_query_for_index_page?).to be(true)
      end

      it 'disallows startup queries for requests paginated with a "before" cursor' do
        allow(helper).to receive(:params).and_return({ unrelated_query_param: 'value', before: 'cursor' })

        expect(helper.use_startup_query_for_index_page?).to be(false)
      end

      it 'disallows startup queries for requests paginated with an "after" cursor' do
        allow(helper).to receive(:params).and_return({ unrelated_query_param: 'value', after: 'cursor' })

        expect(helper.use_startup_query_for_index_page?).to be(false)
      end
    end

    describe '#index_page_startup_query_variables' do
      let_it_be(:project) { build(:project, namespace: create(:group)) }

      before do
        helper.instance_variable_set(:@project, project)
      end

      it 'returns the correct GraphQL variables for the startup query' do
        expect(helper.index_page_startup_query_variables).to eq({
          fullPath: project.full_path,
          sort: 'RELEASED_AT_DESC',
          first: 1
        })
      end
    end
  end
end
