# frozen_string_literal: true

module Gitlab
  module Email
    module Message
      module InProductMarketing
        class Base
          include Gitlab::Email::Message::InProductMarketing::Helper
          include Gitlab::Routing
          include Gitlab::Experiment::Dsl

          attr_accessor :format

          def initialize(group:, user:, series:, format: :html)
            @series = series
            @group = group
            @user = user
            @format = format

            validate_series!
          end

          def subject_line
            raise NotImplementedError
          end

          def tagline
            raise NotImplementedError
          end

          def title
            raise NotImplementedError
          end

          def subtitle
            raise NotImplementedError
          end

          def body_line1
            raise NotImplementedError
          end

          def body_line2
            raise NotImplementedError
          end

          def cta_text
            raise NotImplementedError
          end

          def cta_link
            case format
            when :html
              ActionController::Base.helpers.link_to cta_text, group_email_campaigns_url(group, track: track, series: series), target: '_blank', rel: 'noopener noreferrer'
            else
              [cta_text, group_email_campaigns_url(group, track: track, series: series)].join(' >> ')
            end
          end

          def invite_members?
            false
          end

          def invite_text
            s_('InProductMarketing|Do you have a teammate who would be perfect for this task?')
          end

          def invite_link
            action_link(s_('InProductMarketing|Invite them to help out.'), group_url(group, open_modal: 'invite_members_for_task'))
          end

          def unsubscribe
            self_managed_preferences_link = marketing_preference_link(track, series)
            unsubscribe_message(self_managed_preferences_link)
          end

          def progress(current: series + 1, total: total_series, track_name: track.to_s.humanize)
            if Gitlab.com?
              s_('InProductMarketing|This is email %{current_series} of %{total_series} in the %{track} series.') % { current_series: current, total_series: total, track: track_name }
            else
              s_('InProductMarketing|This is email %{current_series} of %{total_series} in the %{track} series. To disable notification emails sent by your local GitLab instance, either contact your administrator or %{unsubscribe_link}.') % { current_series: current, total_series: total, track: track_name, unsubscribe_link: unsubscribe_link }
            end
          end

          def logo_path
            ["mailers/in_product_marketing", "#{track}-#{series}.png"].join('/')
          end

          def series?
            total_series > 0
          end

          protected

          attr_reader :group, :user, :series

          private

          def track
            self.class.name.demodulize.underscore.to_sym
          end

          def total_series
            Namespaces::InProductMarketingEmailsService::TRACKS[track][:interval_days].size
          end

          def marketing_preference_link(track, series)
            params = {
              utm_source: 'SM',
              utm_medium: 'email',
              utm_campaign: 'onboarding',
              utm_term: "#{track}_#{series}"
            }

            preference_link = "https://about.gitlab.com/company/preference-center/?#{params.to_query}"

            link(s_('InProductMarketing|update your preferences'), preference_link)
          end

          def validate_series!
            raise ArgumentError, "Only #{total_series} series available for this track." unless @series.between?(0, total_series - 1)
          end
        end
      end
    end
  end
end
