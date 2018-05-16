module ClustersHelper
  def has_multiple_clusters?(project)
    project.feature_available?(:multiple_clusters)
  end

  def render_gcp_signup_offer
    return unless show_gcp_signup_offer?

    content_tag :section, class: 'no-animate expanded' do
      render 'projects/clusters/gcp_signup_offer_banner'
    end
  end
end
