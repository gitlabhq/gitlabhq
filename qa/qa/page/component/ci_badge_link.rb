# frozen_string_literal: true

module QA
  module Page
    module Component
      module CiBadgeLink
        extend QA::Page::PageConcern

        COMPLETED_STATUSES = %w[Passed Failed Canceled Blocked Skipped Manual].freeze # excludes Created, Pending, Running
        INCOMPLETE_STATUSES = %w[Pending Created Running].freeze

        # e.g. def passed?(timeout: nil); status_badge == 'Passed'; end
        COMPLETED_STATUSES.map do |status|
          define_method "#{status.downcase}?" do |timeout: nil|
            timeout ? completed?(timeout: timeout) : completed?
            status_badge == status
          end

          # has_passed? => passed?
          # has_failed? => failed?
          alias_method :"has_#{status.downcase}?", :"#{status.downcase}?"
        end

        # e.g. def pending?; status_badge == 'Pending'; end
        INCOMPLETE_STATUSES.map do |status|
          define_method "#{status.downcase}?" do
            status_badge == status
          end
        end

        def self.included(base)
          super

          base.view 'app/assets/javascripts/vue_shared/components/ci_badge_link.vue' do
            element 'ci-badge-link'
          end
        end

        def status_badge
          find_element('ci-badge-link').text
        end

        def completed?(timeout: 60)
          wait_until(reload: false, sleep_interval: 3.0, max_duration: timeout) do
            COMPLETED_STATUSES.include?(status_badge)
          end
        end
      end
    end
  end
end
