# frozen_string_literal: true

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
      prepend Concerns::PipelineTimingCheck

      def call
        doc.xpath('descendant-or-self::text()').each do |node|
          content = node.to_html

          html = trailer_filter(content)

          next if html == content

          node.replace("\n\n#{html}")
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
      #
      # The code intentionally avoids using Regex for security and performance
      # reasons: https://gitlab.com/gitlab-org/gitlab/-/issues/363734
      def trailer_filter(text)
        text.lines.map! do |line|
          trailer, rest = line.split(':', 2)

          next line unless trailer.downcase.end_with?('-by') && rest.present?

          chunks = rest.split
          author_email = chunks.pop.delete_prefix('&lt;').delete_suffix('&gt;')
          next line unless Devise.email_regexp.match(author_email)

          author_name = chunks.join(' ').strip
          trailer = "#{trailer.strip}:"

          "#{trailer} #{link_to_user_or_email(author_name, author_email, trailer)}\n"
        end.join
      end

      # Find a GitLab user using the supplied email and generate
      # a valid link to them, otherwise, generate a mailto link.
      #
      # name - String name used in the commit message for the user
      # email - String email used in the commit message for the user
      # trailer - String trailer used in the commit message
      #
      # Returns a String with a link to the user.
      def link_to_user_or_email(name, email, trailer)
        link_to_user User.with_public_email(email).first,
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
          has_tooltip: false,
          only_path: false
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
        data.compact.transform_keys { |key| %(data-#{key.to_s.dasherize}) }
      end
    end
  end
end
