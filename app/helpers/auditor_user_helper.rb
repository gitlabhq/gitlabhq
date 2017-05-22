module AuditorUserHelper
  def license_allows_auditor_user?
    @license_allows_auditor_user ||= (::License.current&.feature_available?(:auditor_user))
  end
end
