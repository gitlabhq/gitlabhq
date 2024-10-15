# frozen_string_literal: true

module QA
  RSpec.shared_context 'work item epics migration' do
    def work_item_epics_enabled_for_group?(group)
      group.visit!
      QA::Page::Group::Menu.perform(&:go_to_epics)
      EE::Page::Group::WorkItem::Epic::Index.perform(&:work_item_epics_enabled?)
    end
  end
end
