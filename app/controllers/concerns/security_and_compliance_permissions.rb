# frozen_string_literal: true

module SecurityAndCompliancePermissions
  extend ActiveSupport::Concern

  included do
    before_action :ensure_security_and_compliance_enabled!
  end

  private

  def ensure_security_and_compliance_enabled!
    render_404 unless can?(current_user, :access_security_and_compliance, project)
  end
end
