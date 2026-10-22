# frozen_string_literal: true

module Onboarding
  module FeatureLibrary
    # Describes the paid features the Feature catalog's Explore pages show. Lives in CE so CE
    # and EE read the same content; entitlement still comes from the sidebar, never from here.
    module Catalog
      PANELS = %i[group project].freeze
      TIER_PAGES = %i[premium ultimate].freeze
      DEPLOYMENTS = %i[saas self_managed].freeze

      # Super sidebar category menus with their titles, in the order the sidebar renders them. Titles
      # live here because CE can't build the EE-only menus; the drift spec checks they match the nav.
      CATEGORIES = {
        manage_menu: N_('Navigation|Manage'),
        plan_menu: N_('Navigation|Plan'),
        duo_agents_menu: N_('DuoAgentsPlatform|AI'),
        code_menu: N_('Navigation|Code'),
        build_menu: N_('Navigation|Build'),
        secure_menu: N_('Navigation|Secure'),
        deploy_menu: N_('Navigation|Deploy'),
        operations_menu: N_('Navigation|Operate'),
        monitor_menu: N_('Navigation|Monitor'),
        analyze_menu: N_('Navigation|Analyze'),
        observability_menu: N_('Navigation|Observe'),
        observe_menu: N_('Navigation|Observe')
      }.freeze

      # Nav item tiers each page includes. The Ultimate page is cumulative, so it also includes Premium.
      INCLUDED_TIERS = {
        premium: %i[premium add_on],
        ultimate: %i[premium ultimate add_on]
      }.freeze

      # The placeholders a capability description may declare. The endpoint fills each one per viewer.
      DESCRIPTION_VARIABLES = %i[plan_minutes base_minutes base_plan].freeze

      class << self
        def nav_items
          @nav_items ||= (GroupPanel::NAV_ITEMS + ProjectPanel::NAV_ITEMS).freeze
        end

        def capabilities
          @capabilities ||= (GroupPanel::CAPABILITIES + ProjectPanel::CAPABILITIES).freeze
        end

        def find_nav_item(panel, item_id)
          nav_items.find { |item| item.panel == panel && item.item_id == item_id }
        end

        # Explore page content for both tier pages, before any viewer-specific filtering
        # (plan, sidebar entitlement), which is the endpoint's job.
        def explore_pages(panel:, deployment:)
          TIER_PAGES.index_with { |page| explore_page(page, panel: panel, deployment: deployment) }
        end

        private

        def explore_page(page, panel:, deployment:)
          capabilities = capabilities_for(panel, deployment, page)
          highlights = capabilities.select { |capability| capability.tier == page }
          credits = capabilities.select { |capability| capability.tier == :add_on }
          superseded = (highlights + credits).flat_map(&:supersedes_nav_items)

          items = nav_items_for(panel, deployment).reject { |item| superseded.include?(item.item_id) }

          ExplorePage.new(
            highlights: highlights,
            credits: credits,
            new_items: items.select { |item| INCLUDED_TIERS[page].include?(item.tier) },
            enhanced_items: items.filter_map { |item| item.enhancement_for(page) }
          )
        end

        def nav_items_for(panel, deployment)
          nav_items.select { |item| item.panel == panel && item.shown_on_deployments.include?(deployment) }
        end

        def capabilities_for(panel, deployment, page)
          capabilities.select do |capability|
            capability.panel == panel &&
              capability.shown_on_deployments.include?(deployment) &&
              capability.pages_on(deployment).include?(page)
          end
        end
      end
    end
  end
end
