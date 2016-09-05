require 'spec_helper'

describe "Dashboard Issues Feed", feature: true  do
  describe "GET /issues" do
    let!(:user)     { create(:user) }
    let!(:project1) { create(:project) }
    let!(:project2) { create(:project) }

    before do
      project1.team << [user, :master]
      project2.team << [user, :master]
    end

    describe "atom feed" do
      it "renders atom feed via private token" do
        visit issues_dashboard_path(:atom, private_token: user.private_token)

        expect(response_headers['Content-Type']).to have_content('application/atom+xml')
        expect(body).to have_selector('title', text: "#{user.name} issues")
      end

      context "issue with basic fields" do
        let!(:issue2) { create(:issue, author: user, assignee: user, project: project2, description: 'test desc') }

        it "renders issue fields" do
          visit issues_dashboard_path(:atom, private_token: user.private_token)

          entry = find(:xpath, "//feed/entry[contains(summary/text(),'#{issue2.title}')]")

          expect(entry).to be_present
          expect(entry).to have_selector('author email', text: issue2.author_email)
          expect(entry).to have_selector('assignee email', text: issue2.author_email)
          expect(entry).not_to have_selector('labels')
          expect(entry).not_to have_selector('milestone')
          expect(entry).to have_selector('description', text: issue2.description)
        end
      end

      context "issue with label and milestone" do
        let!(:milestone1) { create(:milestone, project: project1, title: 'v1') }
        let!(:label1)     { create(:label, subject: project1, title: 'label1') }
        let!(:issue1)     { create(:issue, author: user, assignee: user, project: project1, milestone: milestone1) }

        before do
          issue1.labels << label1
        end

        it "renders issue label and milestone info" do
          visit issues_dashboard_path(:atom, private_token: user.private_token)

          entry = find(:xpath, "//feed/entry[contains(summary/text(),'#{issue1.title}')]")

          expect(entry).to be_present
          expect(entry).to have_selector('author email', text: issue1.author_email)
          expect(entry).to have_selector('assignee email', text: issue1.author_email)
          expect(entry).to have_selector('labels label', text: label1.title)
          expect(entry).to have_selector('milestone', text: milestone1.title)
          expect(entry).not_to have_selector('description')
        end
      end
    end
  end
end
