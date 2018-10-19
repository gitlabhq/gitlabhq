# frozen_string_literal: true

module ClustersHelper
  # EE overrides this
  def has_multiple_clusters?
    false
  end

  def clusterable
    @project
  end

  def can_create_cluster?
    can?(current_user, :create_cluster, clusterable)
  end

  def render_gcp_signup_offer
    return if Gitlab::CurrentSettings.current_application_settings.hide_third_party_offers?
    return unless show_gcp_signup_offer?

    content_tag :section, class: 'no-animate expanded' do
      render 'clusters/gcp_signup_offer_banner'
    end
  end

  def hidden_clusterable_fields
    clusterable_params.map do |key, value|
      hidden_field_tag(key, value)
    end.reduce(&:safe_concat)
  end

  def clusterable_params
    case clusterable
    when Project
      { project_id: clusterable.to_param, namespace_id: clusterable.namespace.to_param }
    else
      {}
    end
  end
end
