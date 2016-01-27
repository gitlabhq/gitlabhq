# == ProjectsListing
#
# Controller concern to handle projects list filtering & sorting
module ProjectsListing
  extend ActiveSupport::Concern
  include SortingHelper

  FILTERS_WHITELIST = %w[all personal]

  private

  def init_filter_and_sort
    @filter = whitelist_filter(params[:filter], 'all')
    @sort   = whitelist_sort(params[:sort], 'recently_active')
  end

  def whitelist_filter(filter, default)
    FILTERS_WHITELIST.include?(filter) ? filter : default
  end

  def whitelist_sort(sort, default)
    sort_options_hash.has_key?(sort) ? sort : default
  end

  def filter_listing(relation)
    apply_filter(apply_base_scopes(relation)).sort(@sort)
  end

  def apply_base_scopes(relation)
    relation.non_archived.includes(:namespace)
  end

  def apply_filter(relation)
    if current_user && @filter == 'personal'
      relation.personal(current_user)
    else
      relation
    end
  end

end
