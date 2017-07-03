module AuditorUserHelper
  def license_allows_auditor_user?
    @license_allows_auditor_user ||= ::License.feature_available?(:auditor_user)
  end
end
