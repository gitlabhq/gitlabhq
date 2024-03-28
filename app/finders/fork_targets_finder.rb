# frozen_string_literal: true

class ForkTargetsFinder
  def initialize(project, user)
    @project = project
    @user = user
  end

  def execute(options = {})
    items = fork_targets(options)

    by_search(items, options)
  end

  private

  attr_reader :project, :user

  def by_search(items, options)
    return items if options[:search].blank?

    if Feature.enabled?(:fork_targets_finder_with_parents, user)
      # Ideally, we should use `items.search(options[:search], include_parents: true)` option
      # But the resulted query has a terrible performance. See issue: https://gitlab.com/gitlab-org/gitlab/-/issues/437731.
      #
      # As a workaround, we can fetch the group's name from the path and search by it.
      search = options[:search].to_s.split('/').last

      items.search(search)
    else
      items.search(options[:search])
    end
  end

  def fork_targets(options)
    if options[:only_groups]
      Groups::AcceptingProjectCreationsFinder.new(user).execute # rubocop: disable CodeReuse/Finder
    else
      user.forkable_namespaces.sort_by_type
    end
  end
end

ForkTargetsFinder.prepend_mod_with('ForkTargetsFinder')
