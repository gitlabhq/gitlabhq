module Banzai
  module Filter
    # HTML filter that replaces users' names and emails in commit trailers
    # with links to their GitLab accounts or mailto links to their mentioned
    # emails.
    #
    # Commit trailers are special labels in the form of `*-by:` and fall on a
    # single line, ex:
    #
    #   Reported-By: John S. Doe <john.doe@foo.bar>
    #
    # More info about this can be found here:
    # * https://git.wiki.kernel.org/index.php/CommitMessageConventions
    class CommitTrailersFilter < HTML::Pipeline::Filter
      include ActionView::Helpers::TagHelper
      include AvatarsHelper

      TRAILER_REGEXP = /(?<label>[[:alpha:]-]+-by:)/i.freeze
      AUTHOR_REGEXP = /(?<author_name>.+)/.freeze
      # Devise.email_regexp wouldn't work here since its designed to match
      # against strings that only contains email addresses; the \A and \z
      # around the expression will only match if the string being matched
      # contains just the email nothing else.
      MAIL_REGEXP = /&lt;(?<author_email>[^@\s]+@[^@\s]+)&gt;/.freeze
      FILTER_REGEXP = /(?<trailer>^\s*#{TRAILER_REGEXP}\s*#{AUTHOR_REGEXP}\s+#{MAIL_REGEXP}$)/mi.freeze

      def call
        doc.xpath('descendant-or-self::text()').each do |node|
          content = node.to_html

          next unless content.match(FILTER_REGEXP)

          html = trailer_filter(content)

          next if html == content

          node.replace(html)
        end

        doc
      end

      private

      # Replace trailer lines with links to GitLab users or mailto links to
      # non GitLab users.
      #
      # text - String text to replace trailers in.
      #
      # Returns a String with all trailer lines replaced with links to GitLab
      # users and mailto links to non GitLab users. All links have `data-trailer`
      # and `data-user` attributes attached.
      def trailer_filter(text)
        text.gsub(FILTER_REGEXP) do |author_match|
          label = $~[:label]
          "#{label} #{parse_user($~[:author_name], $~[:author_email], label)}"
        end
      end

      # Find a GitLab user using the supplied email and generate
      # a valid link to them, otherwise, generate a mailto link.
      #
      # name - String name used in the commit message for the user
      # email - String email used in the commit message for the user
      # trailer - String trailer used in the commit message
      #
      # Returns a String with a link to the user.
      def parse_user(name, email, trailer)
        link_to_user User.find_by_any_email(email),
          name: name,
          email: email,
          trailer: trailer
      end

      def urls
        Gitlab::Routing.url_helpers
      end

      def link_to_user(user, name:, email:, trailer:)
        wrapper = link_wrapper(data: {
          trailer: trailer,
          user: user.try(:id)
        })

        avatar = user_avatar_without_link(
          user: user,
          user_email: email,
          css_class: 'avatar-inline',
          has_tooltip: false
        )

        link_href = user.nil? ? "mailto:#{email}" : urls.user_url(user)

        avatar_link = link_tag(
          link_href,
          content: avatar,
          title: email
        )

        name_link = link_tag(
          link_href,
          content: name,
          title: email
        )

        email_link = link_tag(
          "mailto:#{email}",
          content: email,
          title: email
        )

        wrapper << "#{avatar_link}#{name_link} <#{email_link}>"
      end

      def link_wrapper(data: {})
        data_attributes = data_attributes_from_hash(data)

        doc.document.create_element(
          'span',
          data_attributes
        )
      end

      def link_tag(url, title: "", content: "", data: {})
        data_attributes = data_attributes_from_hash(data)

        attributes = data_attributes.merge(
          href: url,
          title: title
        )

        link = doc.document.create_element('a', attributes)

        if content.html_safe?
          link << content
        else
          link.content = content # make sure we escape content using nokogiri's #content=
        end

        link
      end

      def data_attributes_from_hash(data = {})
        data.reject! {|_, value| value.nil?}
        data.map do |key, value|
          [%(data-#{key.to_s.dasherize}), value]
        end.to_h
      end
    end
  end
end
