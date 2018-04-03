require "spec_helper"

describe "User sorts issues" do
  set(:project) { create(:project_empty_repo, :public) }
  set(:issue1) { create(:issue, project: project) }
  set(:issue2) { create(:issue, project: project) }
  set(:issue3) { create(:issue, project: project) }

  before do
    create_list(:award_emoji, 2, :upvote, awardable: issue1)
    create_list(:award_emoji, 2, :downvote, awardable: issue2)
    create(:award_emoji, :downvote, awardable: issue1)
    create(:award_emoji, :upvote, awardable: issue2)

    visit(project_issues_path(project))
  end

  it "sorts by popularity" do
    find("button.dropdown-toggle").click

    page.within(".content ul.dropdown-menu.dropdown-menu-align-right li") do
      click_link("Popularity")
    end

    page.within(".issues-list") do
      page.within("li.issue:nth-child(1)") do
        expect(page).to have_content(issue1.title)
        expect(page).to have_content("2 1")
      end

      page.within("li.issue:nth-child(2)") do
        expect(page).to have_content(issue2.title)
        expect(page).to have_content("1 2")
      end

      page.within("li.issue:nth-child(3)") do
        expect(page).to have_content(issue3.title)
        expect(page).not_to have_content("0 0")
      end
    end
  end
end
