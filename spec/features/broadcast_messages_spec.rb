# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Broadcast Messages', feature_category: :notifications do
  include Spec::Support::Helpers::ModalHelpers

  let_it_be(:user) { create(:user) }
  let(:path) { explore_projects_path }
  let(:sign_in_user) { ->(user) { gitlab_sign_in(user) } }

  shared_examples 'a Broadcast Messages' do |type|
    it 'shows broadcast message' do
      visit path

      expect(page).to have_content 'SampleMessage'
    end

    it 'renders styled links' do
      create(:broadcast_message, type, message: "<a href='gitlab.com' style='color: purple'>click me</a>")

      visit path

      expected_html = "<p><a href=\"gitlab.com\" style=\"color: purple\">click me</a></p>"
      expect(page.body).to include(expected_html)
    end
  end

  shared_examples 'a dismissible Broadcast Messages' do
    it 'hides broadcast message after dismiss', :js do
      visit path

      expect_to_be_on_explore_projects_page

      within('body.page-initialised') do
        find(".js-dismiss-current-broadcast-notification[data-id='#{broadcast_message.id}']").click
      end

      expect_message_dismissed
    end

    it 'broadcast message is still hidden after refresh', :js do
      visit path

      expect_to_be_on_explore_projects_page

      within('body.page-initialised') do
        find(".js-dismiss-current-broadcast-notification[data-id='#{broadcast_message.id}']").click
      end

      expect_message_dismissed

      visit path

      expect_message_dismissed
    end

    it 'broadcast message is still hidden after logout and log back in', :js do
      sign_in_user.call(user)

      visit path

      expect_to_be_on_explore_projects_page

      within('body.page-initialised') do
        find(".js-dismiss-current-broadcast-notification[data-id='#{broadcast_message.id}']").click
      end

      expect_message_dismissed

      gitlab_sign_out(user)

      sign_in_user.call(user)

      visit path

      expect_message_dismissed
    end
  end

  describe 'banner type' do
    let_it_be(:broadcast_message) { create(:broadcast_message, message: 'SampleMessage') }

    it_behaves_like 'a Broadcast Messages'

    it 'is not dismissible' do
      visit path

      expect(page).not_to have_selector(".js-dismiss-current-broadcast-notification[data-id=#{broadcast_message.id}]")
    end

    it 'does not replace placeholders' do
      create(:broadcast_message, message: 'Hi {{name}}')

      gitlab_sign_in(user)

      visit path

      expect(page).to have_content 'Hi {{name}}'
    end
  end

  describe 'dismissible banner type' do
    let_it_be(:broadcast_message) { create(:broadcast_message, dismissable: true, message: 'SampleMessage') }

    it_behaves_like 'a Broadcast Messages'

    it_behaves_like 'a dismissible Broadcast Messages'
  end

  describe 'notification type' do
    let_it_be(:broadcast_message) { create(:broadcast_message, :notification, message: 'SampleMessage') }

    it_behaves_like 'a Broadcast Messages', :notification

    it_behaves_like 'a dismissible Broadcast Messages'

    it 'replaces placeholders' do
      create(:broadcast_message, :notification, message: 'Hi {{name}}')

      gitlab_sign_in(user)

      visit path

      expect(page).to have_content "Hi #{user.name}"
    end
  end

  context 'with GitLab revision changes', :js, :use_clean_rails_redis_caching do
    it 'properly shows effects of delete from any revision' do
      text = 'my_broadcast_message'
      message = create(:broadcast_message, broadcast_type: :banner, message: text)
      new_strategy_value = { revision: 'abc123', version: '_version_' }

      visit path

      expect_broadcast_message(message.id, text)

      # seed the other cache
      original_strategy_value = Gitlab::Cache::JsonCache::STRATEGY_KEY_COMPONENTS
      stub_const('Gitlab::Cache::JsonCaches::JsonKeyed::STRATEGY_KEY_COMPONENTS', new_strategy_value)

      page.refresh

      expect_broadcast_message(message.id, text)

      # delete on original cache
      stub_const('Gitlab::Cache::JsonCaches::JsonKeyed::STRATEGY_KEY_COMPONENTS', original_strategy_value)
      admin = create(:admin)
      sign_in(admin)
      enable_admin_mode!(admin)

      visit admin_broadcast_messages_path

      within_testid('message-row', match: :first) do
        find_by_testid("delete-message-#{message.id}").click
      end

      accept_gl_confirm(button_text: 'Delete message')

      visit path

      expect_no_broadcast_message(message.id)

      # other revision of GitLab does gets cache destroyed
      stub_const('Gitlab::Cache::JsonCaches::JsonKeyed::STRATEGY_KEY_COMPONENTS', new_strategy_value)

      page.refresh

      expect_no_broadcast_message(message.id)
    end
  end

  context 'with omniauth' do
    it_behaves_like 'a dismissible Broadcast Messages' do
      let_it_be(:broadcast_message) { create(:broadcast_message, :notification, message: 'SampleMessage') }
      let_it_be(:user) { create(:omniauth_user, extern_uid: 'example-uid', provider: 'saml') }
      let(:sign_in_user) { ->(user) { gitlab_sign_in_via('saml', user, 'example-uid') } }

      before do
        stub_omniauth_saml_config(enabled: true, auto_link_saml_user: true)
      end
    end
  end

  def expect_broadcast_message(id, text)
    within(".js-broadcast-notification-#{id}") do
      expect(page).to have_content text
    end
  end

  def expect_no_broadcast_message(id)
    expect_to_be_on_explore_projects_page

    expect(page).not_to have_selector(".js-broadcast-notification-#{id}")
  end

  def expect_to_be_on_explore_projects_page
    within_testid('explore-projects-title') do
      expect(page).to have_content 'Explore projects'
    end
  end

  def expect_message_dismissed
    expect(page).not_to have_content 'SampleMessage'
  end
end
