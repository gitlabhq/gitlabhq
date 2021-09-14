# frozen_string_literal: true

# Base class, scoped by group
class BaseGroupService < ::BaseContainerService # rubocop:disable Gitlab/NamespacedClass
  attr_accessor :group

  def initialize(group:, current_user: nil, params: {})
    super(container: group, current_user: current_user, params: params)

    @group = group
  end
end
