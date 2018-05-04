require 'spec_helper'

describe "Dashboard Issues Feed"  do
  describe "GET /issues" do
    let!(:user)     { create(:user, email: 'private1@example.com', public_email: 'public1@example.com') }
    let!(:assignee) { create(:user, email: 'private2@example.com', public_email: 'public2@example.com') }
    let!(:project1) { create(:project) }
    let!(:project2) { create(:project) }

    before do
      project1.add_master(user)
      project2.add_master(user)
    end

    describe "atom feed" do
      it "returns 400 if no filter is used" do
        personal_access_token = create(:personal_access_token, user: user)

        visit issues_dashboard_path(:atom, private_token: personal_access_token.token)

        expect(response_headers['Content-Type']).to have_content('application/atom+xml')
        expect(page.status_code).to eq(400)
      end

      it "renders atom feed via personal access token" do
        personal_access_token = create(:personal_access_token, user: user)

        visit issues_dashboard_path(:atom, private_token: personal_access_token.token, assignee_id: user.id)

        expect(response_headers['Content-Type']).to have_content('application/atom+xml')
        expect(body).to have_selector('title', text: "#{user.name} issues")
      end

      it "renders atom feed via RSS token" do
        visit issues_dashboard_path(:atom, rss_token: user.rss_token, assignee_id: user.id)

        expect(response_headers['Content-Type']).to have_content('application/atom+xml')
        expect(body).to have_selector('title', text: "#{user.name} issues")
      end

      it "renders atom feed with url parameters" do
        visit issues_dashboard_path(:atom, rss_token: user.rss_token, state: 'opened', assignee_id: user.id)

        link = find('link[type="application/atom+xml"]')
        params = CGI.parse(URI.parse(link[:href]).query)

        expect(params).to include('rss_token' => [user.rss_token])
        expect(params).to include('state' => ['opened'])
        expect(params).to include('assignee_id' => [user.id.to_s])
      end

      context "issue with basic fields" do
        let!(:issue2) { create(:issue, author: user, assignees: [assignee], project: project2, description: 'test desc') }

        it "renders issue fields" do
          visit issues_dashboard_path(:atom, rss_token: user.rss_token, assignee_id: assignee.id)

          entry = find(:xpath, "//feed/entry[contains(summary/text(),'#{issue2.title}')]")

          expect(entry).to be_present
          expect(entry).to have_selector('author email', text: issue2.author_public_email)
          expect(entry).to have_selector('assignees email', text: assignee.public_email)
          expect(entry).not_to have_selector('labels')
          expect(entry).not_to have_selector('milestone')
          expect(entry).to have_selector('description', text: issue2.description)
        end
      end

      context "issue with label and milestone" do
        let!(:milestone1) { create(:milestone, project: project1, title: 'v1') }
        let!(:label1)     { create(:label, project: project1, title: 'label1') }
        let!(:issue1)     { create(:issue, author: user, assignees: [assignee], project: project1, milestone: milestone1) }

        before do
          issue1.labels << label1
        end

        it "renders issue label and milestone info" do
          visit issues_dashboard_path(:atom, rss_token: user.rss_token, assignee_id: assignee.id)

          entry = find(:xpath, "//feed/entry[contains(summary/text(),'#{issue1.title}')]")

          expect(entry).to be_present
          expect(entry).to have_selector('author email', text: issue1.author_public_email)
          expect(entry).to have_selector('assignees email', text: assignee.public_email)
          expect(entry).to have_selector('labels label', text: label1.title)
          expect(entry).to have_selector('milestone', text: milestone1.title)
          expect(entry).not_to have_selector('description')
        end
      end
    end
  end
end
