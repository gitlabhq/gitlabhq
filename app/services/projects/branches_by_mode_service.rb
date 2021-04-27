# frozen_string_literal: true

# Projects::BranchesByModeService uses Gitaly page-token pagination
# in order to optimally fetch branches.
# The drawback of the page-token pagination is that it doesn't provide
# an option of going to the previous page of the collection.
# That's why we need to fall back to offset pagination when previous page
# is requested.
class Projects::BranchesByModeService
  include Gitlab::Routing

  attr_reader :project, :params

  def initialize(project, params = {})
    @project = project
    @params = params
  end

  def execute
    return fetch_branches_via_gitaly_pagination if use_gitaly_pagination?

    fetch_branches_via_offset_pagination
  end

  private

  def mode
    params[:mode]
  end

  def by_mode(branches)
    return branches unless %w[active stale].include?(mode)

    branches.select { |b| b.state.to_s == mode }
  end

  def use_gitaly_pagination?
    return false if params[:page].present? || params[:search].present?

    Feature.enabled?(:branch_list_keyset_pagination, project, default_enabled: :yaml)
  end

  def fetch_branches_via_offset_pagination
    branches = BranchesFinder.new(project.repository, params).execute
    branches = Kaminari.paginate_array(by_mode(branches)).page(params[:page])

    branches_with_links(branches, last_page: branches.last_page?)
  end

  def fetch_branches_via_gitaly_pagination
    per_page = Kaminari.config.default_per_page
    options = params.merge(per_page: per_page + 1, page_token: params[:page_token])

    branches = BranchesFinder.new(project.repository, options).execute(gitaly_pagination: true)

    # Branch is stale if it hasn't been updated for 3 months
    # This logic is specified in Gitlab Rails and isn't specified in Gitaly
    # To display stale branches we fetch branches sorted as most-stale-at-the-top
    # If the result contains active branches we filter them out and define that no more stale branches left
    # Same logic applies to fetching active branches
    branches = by_mode(branches)
    last_page = branches.size <= per_page

    branches = branches.take(per_page) # rubocop:disable CodeReuse/ActiveRecord

    branches_with_links(branches, last_page: last_page)
  end

  def branches_with_links(branches, last_page:)
    # To fall back to offset pagination we need to track current page via offset param
    # And increase it whenever we go to the next page
    previous_offset = params[:offset].to_i

    previous_path = nil
    next_path = nil

    return [branches, previous_path, next_path] if branches.blank?

    unless last_page
      next_path = project_branches_filtered_path(project, state: mode, page_token: branches.last.name, sort: params[:sort], offset: previous_offset + 1)
    end

    if previous_offset > 0
      previous_path = project_branches_filtered_path(project, state: mode, sort: params[:sort], page: previous_offset, offset: previous_offset - 1)
    end

    [branches, previous_path, next_path]
  end
end
