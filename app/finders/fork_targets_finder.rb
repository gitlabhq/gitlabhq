# frozen_string_literal: true

class ForkTargetsFinder
  def initialize(project, user)
    @project = project
    @user = user
  end

  def execute(options = {})
    return previous_execute(options) unless Feature.enabled?(:searchable_fork_targets)

    items = fork_targets(options)

    by_search(items, options)
  end

  private

  attr_reader :project, :user

  def by_search(items, options)
    return items if options[:search].blank?

    items.search(options[:search])
  end

  def fork_targets(options)
    if options[:only_groups]
      user.manageable_groups(include_groups_with_developer_maintainer_access: true)
    else
      user.forkable_namespaces.sort_by_type
    end
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def previous_execute(options = {})
    return ::Namespace.where(id: user.forkable_namespaces).sort_by_type unless options[:only_groups]

    ::Group.where(id: user.manageable_groups(include_groups_with_developer_maintainer_access: true))
  end
  # rubocop: enable CodeReuse/ActiveRecord
end

ForkTargetsFinder.prepend_mod_with('ForkTargetsFinder')
