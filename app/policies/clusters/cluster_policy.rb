# frozen_string_literal: true

module Clusters
  class ClusterPolicy < BasePolicy
    alias_method :cluster, :subject

    condition(:group_maintainer) { access_level >= GroupMember::MAINTAINER }

    delegate { cluster.project }
    delegate { cluster.groups.first }

    rule { can?(:maintainer_access) }.policy do
      enable :update_cluster
      enable :admin_cluster
    end

    rule { group_maintainer }.policy do
      enable :update_cluster
      enable :admin_cluster
    end

    def access_level
      return GroupMember::NO_ACCESS if @user.nil? || @subject.groups.empty?

      @access_level ||= @subject.groups.first.max_member_access_for_user(@user)
    end
  end
end
