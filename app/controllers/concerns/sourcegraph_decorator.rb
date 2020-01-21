# frozen_string_literal: true

module SourcegraphDecorator
  extend ActiveSupport::Concern

  included do
    before_action :push_sourcegraph_gon, if: :html_request?

    content_security_policy do |p|
      next if p.directives.blank?
      next unless Gitlab::CurrentSettings.sourcegraph_enabled

      default_connect_src = p.directives['connect-src'] || p.directives['default-src']
      connect_src_values = Array.wrap(default_connect_src) | [Gitlab::CurrentSettings.sourcegraph_url]
      p.connect_src(*connect_src_values)
    end
  end

  private

  def push_sourcegraph_gon
    return unless sourcegraph_enabled?

    gon.push({
      sourcegraph: { url: Gitlab::CurrentSettings.sourcegraph_url }
    })
  end

  def sourcegraph_enabled?
    Gitlab::CurrentSettings.sourcegraph_enabled && sourcegraph_enabled_for_project? && current_user&.sourcegraph_enabled
  end

  def sourcegraph_enabled_for_project?
    return false unless project && Gitlab::Sourcegraph.feature_enabled?(project)
    return project.public? if Gitlab::CurrentSettings.sourcegraph_public_only

    true
  end
end
