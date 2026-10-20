# frozen_string_literal: true

module Onboarding
  module FeatureLibrary
    module Catalog
      # A Feature catalog card that is not a nav item on its own, such as Merge controls or
      # GitLab Duo Agent Platform. Premium and Ultimate capabilities are feature highlights;
      # add-on capabilities render under "Powered by GitLab Credits".
      class Capability < Data.define(
        :id, :panel, :tier, :title, :description, :icon, :docs_path, :shown_on_deployments, :supersedes_nav_items
      )
        def initialize(shown_on_deployments: Catalog::DEPLOYMENTS, supersedes_nav_items: [], **attributes)
          super(
            shown_on_deployments: shown_on_deployments.freeze,
            supersedes_nav_items: supersedes_nav_items.freeze,
            **attributes
          )
        end

        def translated_title
          s_(title)
        end

        def translated_description
          s_(description)
        end
      end
    end
  end
end
