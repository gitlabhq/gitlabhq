# frozen_string_literal: true
require 'singleton'

module Gitlab
  class ReleaseBlogPost
    include Singleton

    RELEASE_RSS_URL = 'https://about.gitlab.com/releases.xml'

    def blog_post_url
      @url ||= fetch_blog_post_url
    end

    private

    def fetch_blog_post_url
      installed_version = Gitlab.final_release? ? Gitlab.minor_release : Gitlab.previous_release
      response = Gitlab::HTTP.get(RELEASE_RSS_URL, verify: false)

      return unless response.code == 200

      blog_entry = find_installed_blog_entry(response, installed_version)
      blog_entry['id'] if blog_entry
    end

    def find_installed_blog_entry(response, installed_version)
      response['feed']['entry'].find do |entry|
        entry['release'] == installed_version || matches_previous_release_post(entry['release'], installed_version)
      end
    end

    def should_match_previous_release_post?
      Gitlab.new_major_release? && !Gitlab.final_release?
    end

    def matches_previous_release_post(rss_release_version, installed_version)
      should_match_previous_release_post? && rss_release_version[/\d+/] == installed_version
    end
  end
end
