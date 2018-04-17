require 'spec_helper'

describe 'User sorts merge requests' do
  let!(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let!(:merge_request2) do
    create(:merge_request_with_diffs, source_project: project, target_project: project, source_branch: 'merge-test')
  end
  let(:project) { create(:project, :public, :repository) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    sign_in(user)

    visit(project_merge_requests_path(project))
  end

  it 'keeps the sort option' do
    find('button.dropdown-toggle').click

    page.within('.content ul.dropdown-menu.dropdown-menu-right li') do
      click_link('Last updated')
    end

    visit(merge_requests_dashboard_path(assignee_id: user.id))

    expect(find('.issues-filters')).to have_content('Last updated')

    visit(project_merge_requests_path(project))

    expect(find('.issues-filters')).to have_content('Last updated')
  end

  context 'when merge requests have awards' do
    before do
      create_list(:award_emoji, 2, awardable: merge_request)
      create(:award_emoji, :downvote, awardable: merge_request)

      create(:award_emoji, awardable: merge_request2)
      create_list(:award_emoji, 2, :downvote, awardable: merge_request2)
    end

    it 'sorts by popularity' do
      find('button.dropdown-toggle').click

      page.within('.content ul.dropdown-menu.dropdown-menu-right li') do
        click_link('Popularity')
      end

      page.within('.mr-list') do
        page.within('li.merge-request:nth-child(1)') do
          expect(page).to have_content(merge_request.title)
          expect(page).to have_content('2 1')
        end

        page.within('li.merge-request:nth-child(2)') do
          expect(page).to have_content(merge_request2.title)
          expect(page).to have_content('1 2')
        end
      end
    end
  end
end
