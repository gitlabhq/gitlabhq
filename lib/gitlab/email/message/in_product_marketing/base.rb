# frozen_string_literal: true

module Gitlab
  module Email
    module Message
      module InProductMarketing
        class Base
          include Gitlab::Email::Message::InProductMarketing::Helper
          include Gitlab::Routing

          attr_accessor :format

          def initialize(group:, user:, series:, format: :html)
            raise ArgumentError, "Only #{total_series} series available for this track." unless series.between?(0, total_series - 1)

            @group = group
            @user = user
            @series = series
            @format = format
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
              link_to cta_text, group_email_campaigns_url(group, track: track, series: series), target: '_blank', rel: 'noopener noreferrer'
            else
              [cta_text, group_email_campaigns_url(group, track: track, series: series)].join(' >> ')
            end
          end

          def unsubscribe
            parts = Gitlab.com? ? unsubscribe_com : unsubscribe_self_managed(track, series)

            case format
            when :html
              parts.join(' ')
            else
              parts.join("\n" + ' ' * 16)
            end
          end

          def progress
            if Gitlab.com?
              s_('InProductMarketing|This is email %{current_series} of %{total_series} in the %{track} series.') % { current_series: series + 1, total_series: total_series, track: track.to_s.humanize }
            else
              s_('InProductMarketing|This is email %{current_series} of %{total_series} in the %{track} series. To disable notification emails sent by your local GitLab instance, either contact your administrator or %{unsubscribe_link}.') % { current_series: series + 1, total_series: total_series, track: track.to_s.humanize, unsubscribe_link: unsubscribe_link }
            end
          end

          def address
            s_('InProductMarketing|%{strong_start}GitLab Inc.%{strong_end} 268 Bush Street, #350, San Francisco, CA 94104, USA').html_safe % strong_options
          end

          def footer_links
            links = [
              [s_('InProductMarketing|Blog'), 'https://about.gitlab.com/blog'],
              [s_('InProductMarketing|Twitter'), 'https://twitter.com/gitlab'],
              [s_('InProductMarketing|Facebook'), 'https://www.facebook.com/gitlab'],
              [s_('InProductMarketing|YouTube'), 'https://www.youtube.com/channel/UCnMGQ8QHMAnVIsI3xJrihhg']
            ]
            case format
            when :html
              links.map do |text, link|
                link_to(text, link)
              end
            else
              '| ' + links.map do |text, link|
                [text, link].join(' ')
              end.join("\n| ")
            end
          end

          def logo_path
            ["mailers/in_product_marketing", "#{track}-#{series}.png"].join('/')
          end

          protected

          attr_reader :group, :user, :series

          private

          def track
            self.class.name.demodulize.downcase.to_sym
          end

          def total_series
            Namespaces::InProductMarketingEmailsService::TRACKS[track][:interval_days].size
          end

          def unsubscribe_com
            [
              s_('InProductMarketing|If you no longer wish to receive marketing emails from us,'),
              s_('InProductMarketing|you may %{unsubscribe_link} at any time.') % { unsubscribe_link: unsubscribe_link }
            ]
          end

          def unsubscribe_self_managed(track, series)
            [
              s_('InProductMarketing|To opt out of these onboarding emails, %{unsubscribe_link}.') % { unsubscribe_link: unsubscribe_link },
              s_("InProductMarketing|If you don't want to receive marketing emails directly from GitLab, %{marketing_preference_link}.") % { marketing_preference_link: marketing_preference_link(track, series) }
            ]
          end

          def unsubscribe_link
            unsubscribe_url = Gitlab.com? ? '%tag_unsubscribe_url%' : profile_notifications_url

            link(s_('InProductMarketing|unsubscribe'), unsubscribe_url)
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
        end
      end
    end
  end
end
