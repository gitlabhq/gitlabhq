# frozen_string_literal: true

module Gitlab
  module Email
    module Message
      class BuildIosAppGuide
        include Gitlab::Email::Message::InProductMarketing::Helper
        include Gitlab::Routing

        attr_accessor :format

        def initialize(format: :html)
          @format = format
        end

        def subject_line
          s_('InProductMarketing|Get set up to build for iOS')
        end

        def title
          s_("InProductMarketing|Building for iOS? We've got you covered.")
        end

        def body_line1
          s_(
            'InProductMarketing|Want to get your iOS app up and running, including publishing all the way to ' \
            'TestFlight? Follow our guide to set up GitLab and fastlane to publish iOS apps to the App Store.'
          )
        end

        def cta_text
          s_('InProductMarketing|Learn how to build for iOS')
        end

        def cta_link
          action_link(cta_text, 'https://about.gitlab.com/blog/2019/03/06/ios-publishing-with-gitlab-and-fastlane/')
        end

        def cta2_text
          s_('InProductMarketing|Watch iOS building in action.')
        end

        def cta2_link
          action_link(cta2_text, 'https://www.youtube.com/watch?v=325FyJt7ZG8')
        end

        def logo_path
          'mailers/in_product_marketing/create-0.png'
        end

        def unsubscribe
          unsubscribe_message
        end
      end
    end
  end
end
