# frozen_string_literal: true

module Authn
  class OauthApplicationPolicy < BasePolicy
    condition(:is_owner) { @subject.owner == @user }

    with_scope :subject
    condition(:instance_application) { @subject.owner.nil? && !@subject.dynamic? }

    condition(:group_owner) { @subject.owner.is_a?(::Group) && can?(:admin_group, @subject.owner) }

    # An instance application has no owner, so is_owner would match a missing user
    rule { anonymous }.prevent_all

    rule { is_owner }.enable :read_oauth_application
    rule { is_owner }.enable :update_oauth_application
    rule { is_owner }.enable :delete_oauth_application

    rule { is_owner | group_owner | (instance_application & admin) }.enable :update_oauth_application_granular_scope
  end
end
