module AuditorUserHelper
  include ::Gitlab::Utils::StrongMemoize

  def license_allows_auditor_user?
    strong_memoize(:license_allows_auditor_user) do
      ::License.feature_available?(:auditor_user)
    end
  end
end
