# frozen_string_literal: true

module QA
  module Page
    module Component
      module CiIcon
        extend QA::Page::PageConcern

        # rubocop:disable Layout/LineLength
        COMPLETED_STATUSES = %w[Passed Failed Canceled Blocked Skipped Manual].freeze # excludes Created, Pending, Running
        # rubocop:enable Layout/LineLength
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

          base.view 'app/assets/javascripts/vue_shared/components/ci_icon/ci_icon.vue' do
            element 'ci-icon-text'
          end
        end

        def status_badge
          # There are more than 1 on job details page
          all_elements('ci-icon-text', minimum: 1).first.text
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
