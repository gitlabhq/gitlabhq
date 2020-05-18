# frozen_string_literal: true

module QA
  module Page
    module Component
      module CiBadgeLink
        extend QA::Page::PageConcern

        COMPLETED_STATUSES = %w[passed failed canceled blocked skipped manual].freeze # excludes created, pending, running
        INCOMPLETE_STATUSES = %w[pending created running].freeze

        # e.g. def passed?(timeout: nil); status_badge == 'passed'; end
        COMPLETED_STATUSES.map do |status|
          define_method "#{status}?" do |timeout: nil|
            timeout ? completed?(timeout: timeout) : completed?
            status_badge == status
          end

          # has_passed? => passed?
          # has_failed? => failed?
          alias_method :"has_#{status}?", :"#{status}?"
        end

        # e.g. def pending?; status_badge == 'pending'; end
        INCOMPLETE_STATUSES.map do |status|
          define_method "#{status}?" do
            status_badge == status
          end
        end

        def self.included(base)
          super

          base.view 'app/assets/javascripts/vue_shared/components/ci_badge_link.vue' do
            element :status_badge
          end
        end

        def status_badge
          find_element(:status_badge).text
        end

        private

        def completed?(timeout: 60)
          wait_until(reload: false, max_duration: timeout) do
            COMPLETED_STATUSES.include?(status_badge)
          end
        end
      end
    end
  end
end
