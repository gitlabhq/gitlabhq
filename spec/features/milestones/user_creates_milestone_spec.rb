# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "User creates milestone", :js, feature_category: :team_planning do
  let_it_be(:developer) { create(:user) }
  let_it_be(:inherited_guest) { create(:user) }
  let_it_be(:inherited_developer) { create(:user) }
  let_it_be(:group) { create(:group, :public, guests: inherited_guest, developers: inherited_developer) }

  shared_examples 'creates milestone' do
    specify do
      title = "v2.3"

      fill_in("Title", with: title)
      fill_in("Description", with: "# Description header")
      click_button("Create milestone")

      expect(page).to have_content(title)
        .and have_content("Issues")
        .and have_header_with_correct_id_and_link(1, "Description header", "description-header")

      visit(activity_project_path(project))

      expect(page).to have_content("#{user.name} #{user.to_reference} opened milestone")
    end
  end

  shared_examples 'renders not found' do
    specify do
      expect(page).to have_title('Not Found')
      expect(page).to have_content('Page not found')
    end
  end

  before do
    sign_in(user)
    visit(new_project_milestone_path(project))
  end

  context 'when project is public' do
    let_it_be(:project) { create(:project, :public, group: group) }

    context 'and issues and merge requests are private' do
      before_all do
        project.project_feature.update!(
          issues_access_level: ProjectFeature::PRIVATE,
          merge_requests_access_level: ProjectFeature::PRIVATE
        )
      end

      context 'when user is an inherited member from the group' do
        context 'and user is a guest' do
          let(:user) { inherited_guest }

          it_behaves_like 'renders not found'
        end

        context 'and user is a developer' do
          let(:user) { inherited_developer }

          it_behaves_like 'creates milestone'
        end
      end
    end
  end

  context 'when project is private' do
    let_it_be(:project) { create(:project, :private, group: group) }

    context 'and user is a direct project member' do
      before_all do
        project.add_developer(developer)
      end

      context 'when user is a developer' do
        let(:user) { developer }

        it_behaves_like 'creates milestone'
      end
    end

    context 'and user is an inherited member from the group' do
      context 'when user is a guest' do
        let(:user) { inherited_guest }

        it_behaves_like 'renders not found'
      end

      context 'when user is a developer' do
        let(:user) { inherited_developer }

        it_behaves_like 'creates milestone'
      end
    end
  end
end
