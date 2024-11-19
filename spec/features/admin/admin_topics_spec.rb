# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin Topics', :with_current_organization, feature_category: :groups_and_projects do
  let_it_be(:topic) { create(:topic, organization: current_organization) }
  let_it_be(:namespace) { create(:namespace, organization: current_organization) }
  let_it_be(:admin) { create(:admin, namespace: namespace) }

  before do
    sign_in(admin)
    enable_admin_mode!(admin)
  end

  describe 'topic edit' do
    it 'shows all breadcrumbs', :js do
      visit edit_admin_topic_path(topic)

      expect(page_breadcrumbs).to eq([
        { text: 'Admin area', href: admin_root_path },
        { text: 'Topics', href: admin_topics_path },
        { text: topic.name, href: edit_admin_topic_path(topic) },
        { text: 'Edit', href: edit_admin_topic_path(topic) }
      ])
    end
  end
end
