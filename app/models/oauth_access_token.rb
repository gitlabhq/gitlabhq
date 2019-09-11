# frozen_string_literal: true

class OauthAccessToken < Doorkeeper::AccessToken
  belongs_to :resource_owner, class_name: 'User'
  belongs_to :application, class_name: 'Doorkeeper::Application'

  alias_attribute :user, :resource_owner

  scope :distinct_resource_owner_counts, ->(applications) { where(application: applications).distinct.group(:application_id).count(:resource_owner_id) }

  def scopes=(value)
    if value.is_a?(Array)
      super(Doorkeeper::OAuth::Scopes.from_array(value).to_s)
    else
      super
    end
  end
end
