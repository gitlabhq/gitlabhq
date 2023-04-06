# frozen_string_literal: true

FactoryBot.define do
  factory :resource_link_event, class: 'WorkItems::ResourceLinkEvent' do
    action { :add }
    issue { association(:issue) }
    user { issue&.author || association(:user) }
    child_work_item { association(:work_item, :task) }
  end
end
