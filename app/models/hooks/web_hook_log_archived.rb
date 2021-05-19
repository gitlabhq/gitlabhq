# frozen_string_literal: true

# This model is not intended to be used.
# It is a temporary reference to the old non-partitioned
# web_hook_logs table.
# Please refer to https://gitlab.com/groups/gitlab-org/-/epics/5558
# for details.
# rubocop:disable Gitlab/NamespacedClass: This is a temporary class with no relevant namespace
#  WebHook, WebHookLog and all hooks are defined outside of a namespace
class WebHookLogArchived < ApplicationRecord
  self.table_name = 'web_hook_logs_archived'
end
