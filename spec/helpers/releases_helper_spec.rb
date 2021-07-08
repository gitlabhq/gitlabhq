# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ReleasesHelper do
  describe '#illustration' do
    it 'returns the correct image path' do
      expect(helper.illustration).to match(%r{illustrations/releases-(\w+)\.svg})
    end
  end

  describe '#help_page' do
    it 'returns the correct link to the help page' do
      expect(helper.help_page).to include('user/project/releases/index')
    end
  end

  context 'url helpers' do
    let(:project) { build(:project, namespace: create(:group)) }
    let(:release) { create(:release, project: project) }
    let(:user) { create(:user) }
    let(:can_user_create_release) { false }
    let(:common_keys) { [:project_id, :project_path, :illustration_path, :documentation_path] }

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
    end

    describe '#data_for_edit_release_page' do
      it 'has the needed data to display the "edit release" page' do
        keys = %i(project_id
                  group_id
                  group_milestones_available
                  project_path
                  tag_name
                  markdown_preview_path
                  markdown_docs_path
                  releases_page_path
                  release_assets_docs_path
                  manage_milestones_path
                  new_milestone_path)

        expect(helper.data_for_edit_release_page.keys).to match_array(keys)
      end
    end

    describe '#data_for_new_release_page' do
      it 'has the needed data to display the "new release" page' do
        keys = %i(project_id
                  group_id
                  group_milestones_available
                  project_path
                  releases_page_path
                  markdown_preview_path
                  markdown_docs_path
                  release_assets_docs_path
                  manage_milestones_path
                  new_milestone_path
                  default_branch)

        expect(helper.data_for_new_release_page.keys).to match_array(keys)
      end
    end

    describe '#data_for_show_page' do
      it 'has the needed data to display the individual "release" page' do
        keys = %i(project_id
                  project_path
                  tag_name)

        expect(helper.data_for_show_page.keys).to match_array(keys)
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
