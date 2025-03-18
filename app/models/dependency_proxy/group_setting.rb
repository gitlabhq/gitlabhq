# frozen_string_literal: true

class DependencyProxy::GroupSetting < ApplicationRecord
  belongs_to :group

  encrypts :identity
  encrypts :secret

  validates :group, presence: true
  validates :identity, presence: true, if: :secret?
  validates :secret, presence: true, if: :identity?
  validates :identity, :secret, length: { maximum: 255 }

  def authorization_header
    return {} unless identity? && secret?

    authorization = ActionController::HttpAuthentication::Basic.encode_credentials(identity, secret)

    { Authorization: authorization }
  end
end
