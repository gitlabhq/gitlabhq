# frozen_string_literal: true

if Gitlab::Runtime.puma? && !Gitlab::Runtime.puma_in_clustered_mode?
  warn 'WARNING: Puma is running in Single mode (workers = 0). Some features may not work. Please refer to https://gitlab.com/groups/gitlab-org/-/epics/5303 for info.'
end
