# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > User sees users dropdowns in issuables list', :js, feature_category: :groups_and_projects do
  include FilteredSearchHelpers

  let(:group) { create(:group) }
  let(:user_in_dropdown) { create(:user) }
  let!(:user_not_in_dropdown) { create(:user) }
  let!(:project) { create(:project, group: group) }

  before do
    group.add_developer(user_in_dropdown)
    sign_in(user_in_dropdown)
  end

  describe 'issues' do
    let!(:issuable) { create(:issue, project: project) }

    %w[Author Assignee].each do |dropdown|
      describe "#{dropdown} dropdown" do
        it 'only includes members of the project/group' do
          visit issues_group_path(group)

          select_tokens dropdown, '=', submit: false

          expect_suggestion(user_in_dropdown.name)
          expect_no_suggestion(user_not_in_dropdown.name)
        end
      end
    end
  end

  describe 'merge requests' do
    let!(:issuable) { create(:merge_request, source_project: project) }

    %w[Author Assignee].each do |dropdown|
      describe "#{dropdown} dropdown" do
        it 'only includes members of the project/group' do
          visit merge_requests_group_path(group)

          select_tokens dropdown, '=', submit: false

          expect_suggestion(user_in_dropdown.name)
          expect_no_suggestion(user_not_in_dropdown.name)
        end
      end
    end

    context 'when vue_merge_request_list feature flag is disabled' do
      before do
        stub_feature_flags(vue_merge_request_list: false)
      end

      %w[author assignee].each do |dropdown|
        describe "#{dropdown} dropdown" do
          it 'only includes members of the project/group' do
            visit merge_requests_group_path(group)

            filtered_search.set("#{dropdown}:=")

            expect(find("#js-dropdown-#{dropdown} .filter-dropdown")).to have_content(user_in_dropdown.name)
            expect(find("#js-dropdown-#{dropdown} .filter-dropdown")).not_to have_content(user_not_in_dropdown.name)
          end
        end
      end
    end
  end
end
