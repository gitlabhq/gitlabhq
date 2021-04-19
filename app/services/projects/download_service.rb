# frozen_string_literal: true

module Projects
  class DownloadService < BaseService
    WHITELIST = [
      /^[^.]+\.fogbugz.com$/
    ].freeze

    def initialize(project, url)
      @project = project
      @url = url
    end

    def execute
      return unless valid_url?(@url)

      uploader = FileUploader.new(@project)
      uploader.download!(@url)
      uploader.store!

      uploader.to_h
    end

    private

    def valid_url?(url)
      url && http?(url) && valid_domain?(url)
    end

    def http?(url)
      url =~ /\A#{URI::DEFAULT_PARSER.make_regexp(%w(http https))}\z/
    end

    def valid_domain?(url)
      host = URI.parse(url).host
      WHITELIST.any? { |entry| entry === host }
    end
  end
end
