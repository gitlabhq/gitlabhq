# frozen_string_literal: true

module QA
  RSpec.shared_context 'work item epics migration' do
    def work_item_epics_enabled_for_group?(group)
      group.visit!
      QA::Page::Group::Menu.perform(&:go_to_epics)
      EE::Page::Group::WorkItem::Epic::Index.perform(&:work_item_epics_enabled?)
    end

    def resource_accessable?(resource_web_url)
      return unless Runtime::Address.valid?(resource_web_url)

      Support::Retrier.retry_until(sleep_interval: 3, max_attempts: 5, raise_on_failure: false) do
        response_check = Support::API.get(resource_web_url)
        response_check.code == 200
      end
    end

    def update_web_url(group, epic)
      # work item epics have a web url containing /-/work_items/ but depending on FF status, it may not be
      # accessible and would be rerouted to /-/epics/
      epic.web_url = "#{group.web_url}/-/epics/#{epic.iid}" unless resource_accessable?(epic.web_url)
    end
  end
end
