#Persists filter state per project or group using cookies
module SearchCookies
  extend ActiveSupport::Concern

  private

  def set_default_sort
    key = if is_a_listing_page_for?('issues') || is_a_listing_page_for?('merge_requests')
            'issuable_sort'
          end

    params[:sort] = get_cookie_value(key)
    params[:sort] ||= 'id_desc'
  end

  #Save cookies based on user sessions
  def get_cookie_value(key)
    return unless key

    subkey = "group_#{@group.id}" if @group.present?
    subkey = "project_#{@project.id}" if @project.present?

    begin
      parsed_cookie = JSON.parse(cookies[key]) if cookies[key].present?
      hash =  parsed_cookie || {}
      hash[subkey] = params[:sort] if params[:sort].present?
      cookies[key] = JSON.generate(hash)
    rescue
      return
    end

    return hash[subkey]
  end

  def is_a_listing_page_for?(page_type)
    controller_name, action_name = params.values_at(:controller, :action)

    (controller_name == "projects/#{page_type}" && action_name == 'index') ||
    (controller_name == 'groups' && action_name == page_type) ||
    (controller_name == 'dashboard' && action_name == page_type)
  end
end
