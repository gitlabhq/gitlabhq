# frozen_string_literal: true

# Shorter routing method for some project items
module GitlabRoutingHelper
  extend ActiveSupport::Concern

  include ::ProjectsHelper
  include ::ApplicationSettingsHelper
  include API::Helpers::RelatedResourcesHelpers
  include ::Routing::ProjectsHelper
  include ::Routing::Projects::MembersHelper
  include ::Routing::Groups::MembersHelper
  include ::Routing::MembersHelper
  include ::Routing::ArtifactsHelper
  include ::Routing::PipelineSchedulesHelper
  include ::Routing::SnippetsHelper
  include ::Routing::WikiHelper
  include ::Routing::GraphqlHelper
  include ::Routing::PseudonymizationHelper
  include ::Routing::PackagesHelper
  included do
    Gitlab::Routing.includes_helpers(self)
  end
end

GitlabRoutingHelper.include_mod_with('GitlabRoutingHelper')
