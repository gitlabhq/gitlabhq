# frozen_string_literal: true

class MergeRequestSidebarBasicEntity < IssuableSidebarBasicEntity
end

MergeRequestSidebarBasicEntity.prepend_if_ee('EE::MergeRequestSidebarBasicEntity')
