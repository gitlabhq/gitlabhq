# frozen_string_literal: true

module MemberPolicyHelpers
  extend ActiveSupport::Concern

  private

  def record_is_access_request_of_self?
    record_is_access_request? && record_belongs_to_self?
  end

  def record_is_access_request?
    @subject.request? # rubocop:disable Gitlab/ModuleWithInstanceVariables
  end

  def record_belongs_to_self?
    @user && @subject.user == @user # rubocop:disable Gitlab/ModuleWithInstanceVariables
  end
end
