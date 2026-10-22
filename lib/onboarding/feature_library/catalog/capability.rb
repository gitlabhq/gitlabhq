# frozen_string_literal: true

module Onboarding
  module FeatureLibrary
    module Catalog
      # A Feature catalog card that is not a nav item on its own, such as Merge controls or
      # GitLab Duo Agent Platform. Premium and Ultimate capabilities are feature highlights;
      # add-on capabilities render under "Powered by GitLab Credits".
      class Capability < Data.define(
        :id, :panel, :tier, :title, :description, :description_variables, :icon, :docs_path,
        :shown_on_deployments, :pages, :supersedes_nav_items
      )
        # description_variables: the %{} placeholders in the description, from Catalog::DESCRIPTION_VARIABLES,
        #   which the endpoint fills per viewer.
        # pages: the tier pages that list an add-on card, per deployment. An Array applies to every
        #   deployment; a Hash sets them for some deployments and leaves the rest on every page.
        #   Highlights only appear on their own tier's page, so they keep the default.
        def initialize(
          description_variables: [], shown_on_deployments: Catalog::DEPLOYMENTS, pages: Catalog::TIER_PAGES,
          supersedes_nav_items: [], **attributes)
          super(
            description_variables: description_variables.freeze,
            shown_on_deployments: shown_on_deployments.freeze,
            pages: pages_by_deployment(pages),
            supersedes_nav_items: supersedes_nav_items.freeze,
            **attributes
          )
        end

        def pages_on(deployment)
          pages.fetch(deployment)
        end

        def translated_title
          s_(title)
        end

        def translated_description(**variables)
          return s_(description) if description_variables.empty?

          missing = description_variables - variables.keys
          raise ArgumentError, "#{id} description needs #{missing.join(', ')}" if missing.any?

          format(s_(description), variables)
        end

        private

        def pages_by_deployment(pages)
          Catalog::DEPLOYMENTS.index_with do |deployment|
            (pages.is_a?(Hash) ? pages.fetch(deployment, Catalog::TIER_PAGES) : pages).freeze
          end.freeze
        end
      end
    end
  end
end
