# frozen_string_literal: true

# TODO: https://gitlab.com/groups/gitlab-org/-/epics/7054
# This file is a part of the Consolidate Group and Project member management epic,
# and will be developed further as we progress through that epic.
class ProjectNamespaceMember < ProjectMember # rubocop:disable Gitlab/NamespacedClass
  self.allow_legacy_sti_class = true
end
