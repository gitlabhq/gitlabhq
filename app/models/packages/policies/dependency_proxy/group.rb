# frozen_string_literal: true

# We use this class, in conjunction with the
# Group#dependency_proxy_for_containers_policy_subject method,
# to specify a custom policy class for DependencyProxy.
# A similar pattern was used in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/90963
module Packages
  module Policies
    module DependencyProxy
      class Group
        attr_reader :group

        delegate :dependency_proxy_feature_available?, :full_path, :licensed_feature_available?,
          :max_member_access_for_user, :member?, :owned_by?, :public?, :root_ancestor,
          :root_ancestor_ip_restrictions, to: :group

        def initialize(group)
          @group = group
        end
      end
    end
  end
end
