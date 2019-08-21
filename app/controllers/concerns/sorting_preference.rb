# frozen_string_literal: true

module SortingPreference
  include SortingHelper
  include CookiesHelper

  def set_sort_order
    set_sort_order_from_user_preference || set_sort_order_from_cookie || params[:sort] || default_sort_order
  end

  # Implement sorting_field method on controllers
  # to choose which column to store the sorting parameter.
  def sorting_field
    nil
  end

  # Implement default_sort_order method on controllers
  # to choose which default sort should be applied if
  # sort param is not provided.
  def default_sort_order
    nil
  end

  # Implement legacy_sort_cookie_name method on controllers
  # to set sort from cookie for backwards compatibility.
  def legacy_sort_cookie_name
    nil
  end

  private

  def set_sort_order_from_user_preference
    return unless current_user
    return unless sorting_field

    user_preference = current_user.user_preference

    sort_param = params[:sort]
    sort_param ||= user_preference[sorting_field]

    return sort_param if Gitlab::Database.read_only?

    if user_preference[sorting_field] != sort_param
      user_preference.update(sorting_field => sort_param)
    end

    sort_param
  end

  def set_sort_order_from_cookie
    return unless legacy_sort_cookie_name

    sort_param = params[:sort] if params[:sort].present?
    # fallback to legacy cookie value for backward compatibility
    sort_param ||= cookies[legacy_sort_cookie_name]
    sort_param ||= cookies[remember_sorting_key]

    sort_value = update_cookie_value(sort_param)
    set_secure_cookie(remember_sorting_key, sort_value)
    sort_value
  end

  # Convert sorting_field to legacy cookie name for backwards compatibility
  # :merge_requests_sort => 'mergerequest_sort'
  # :issues_sort => 'issue_sort'
  def remember_sorting_key
    @remember_sorting_key ||= sorting_field
      .to_s
      .split('_')[0..-2]
      .map(&:singularize)
      .join('')
      .concat('_sort')
  end

  # Update old values to the actual ones.
  def update_cookie_value(value)
    case value
    when 'id_asc'             then sort_value_oldest_created
    when 'id_desc'            then sort_value_recently_created
    when 'downvotes_asc'      then sort_value_popularity
    when 'downvotes_desc'     then sort_value_popularity
    else value
    end
  end
end
