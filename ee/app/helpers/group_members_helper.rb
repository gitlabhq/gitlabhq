module GroupMembersHelper
  def clear_ldap_permission_cache_message
    markdown(
      <<-EOT.strip_heredoc
      Be careful, all members of this group (except you)  will have their
      **access level temporarily downgraded** to `Guest`. The next time that a group member
      signs in to GitLab (or after one hour, whichever occurs first) their access level will
      be updated to the one specified on the Group settings page.
      EOT
    )
  end
end
