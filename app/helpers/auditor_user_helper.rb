module AuditorUserHelper
  def license_allows_auditor_user?
    @license_allows_auditor_user ||= (::License.current && ::License.current.add_on?('GitLab_Auditor_User'))
  end
end
