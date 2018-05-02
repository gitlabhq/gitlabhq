require "spec_helper"

describe "Admin sends notification", :js do
  let(:group) { create(:group) }
  let!(:project) { create(:project, group: group) }
  let(:admin) { create(:admin) }
  let(:user) { create(:user) }

  before do
    group.add_developer(user)

    sign_in(admin)

    visit(admin_email_path)
  end

  it "sends notification" do
    perform_enqueued_jobs do
      NOTIFICATION_TEXT = "Your project has been moved.".freeze
      body = find(:xpath, "//body")

      page.within("form#new-admin-email") do
        fill_in(:subject, with: "My Subject")
        fill_in(:body, with: NOTIFICATION_TEXT)

        find(".ajax-admin-email-select").click

        wait_for_requests

        options = body.all("li.select2-result")

        expect(body).to have_selector("li.select2-result", count: 3)
        expect(options[0].text).to include("All")
        expect(options[1].text).to include(group.name)
        expect(options[2].text).to include(project.name)

        body.find("input.select2-input").set(group.name)
        body.find(".group-name", text: group.name).click

        click_button("Send message")
      end
    end

    emails = ActionMailer::Base.deliveries

    expect(find(".flash-notice")).to have_content("Email sent")
    expect(emails.count).to eql(group.users.count)
    expect(emails.last.text_part.body.decoded).to include(NOTIFICATION_TEXT)
  end
end
