require 'rails_helper'

describe 'Awards Emoji', feature: true do
  let!(:project)   { create(:project) }
  let!(:user)      { create(:user) }

  before do
    project.team << [user, :master]
    login_as(user)
  end

  describe 'Click award emoji from issue#show' do
    let!(:issue) do
      create(:issue,
             assignee: @user,
             project: project)
    end

    before do
      visit namespace_project_issue_path(project.namespace, project, issue)
    end

    it 'increments the thumbsdown emoji', js: true do
      find('[data-emoji="thumbsdown"]').click
      sleep 2
      expect(thumbsdown_emoji).to have_text("1")
    end

    context 'click the thumbsup emoji' do
      it 'increments the thumbsup emoji', js: true do
        find('[data-emoji="thumbsup"]').click
        sleep 2
        expect(thumbsup_emoji).to have_text("1")
      end

      it 'decrements the thumbsdown emoji', js: true do
        expect(thumbsdown_emoji).to have_text("0")
      end
    end

    context 'click the thumbsdown emoji' do
      it 'increments the thumbsdown emoji', js: true do
        find('[data-emoji="thumbsdown"]').click
        sleep 2
        expect(thumbsdown_emoji).to have_text("1")
      end

      it 'decrements the thumbsup emoji', js: true do
        expect(thumbsup_emoji).to have_text("0")
      end
    end
  end

  def thumbsup_emoji
    page.all('span.js-counter').first
  end

  def thumbsdown_emoji
    page.all('span.js-counter').last
  end
end
