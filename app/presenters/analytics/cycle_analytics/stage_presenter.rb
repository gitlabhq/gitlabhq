# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class StagePresenter < Gitlab::View::Presenter::Delegated
      def title
        extract_default_stage_attribute(:title) || name
      end

      def description
        extract_default_stage_attribute(:description) || ''
      end

      def legend
        ''
      end

      private

      def extract_default_stage_attribute(attribute)
        default_stage_attributes.dig(name.to_sym, attribute.to_sym)
      end

      def default_stage_attributes
        @default_stage_attributes ||= {
          issue: {
            title: s_('CycleAnalyticsStage|Issue'),
            description: _('Time before an issue gets scheduled')
          },
          plan: {
            title: s_('CycleAnalyticsStage|Plan'),
            description: _('Time before an issue starts implementation')
          },
          code: {
            title: s_('CycleAnalyticsStage|Code'),
            description: _('Time until first merge request')
          },
          test: {
            title: s_('CycleAnalyticsStage|Test'),
            description: _('Total test time for all commits/merges')
          },
          review: {
            title: s_('CycleAnalyticsStage|Review'),
            description: _('Time between merge request creation and merge/close')
          },
          staging: {
            title: s_('CycleAnalyticsStage|Staging'),
            description: _('From merge request merge until deploy to production')
          },
          production: {
            title: s_('CycleAnalyticsStage|Total'),
            description: _('From issue creation until deploy to production')
          }
        }.freeze
      end
    end
  end
end
