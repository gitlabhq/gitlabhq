# frozen_string_literal: true

class ForkTargetsFinder
  def initialize(project, user)
    @project = project
    @user = user
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def execute(options = {})
    return ::Namespace.where(id: user.manageable_namespaces).sort_by_type unless options[:only_groups]

    ::Group.where(id: user.manageable_groups)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  private

  attr_reader :project, :user
end

ForkTargetsFinder.prepend_mod_with('ForkTargetsFinder')
