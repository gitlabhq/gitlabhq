# frozen_string_literal: true

# Class to parse manifest file and build a list of repositories for import
#
# <manifest>
#   <remote review="https://android-review.googlesource.com/" />
#   <project path="platform-common" name="platform" />
#   <project path="platform/art" name="platform/art" />
#   <project path="platform/device" name="platform/device" />
# </manifest>
#
# 1. Project path must be uniq and can't be part of other project path.
#    For example, you can't have projects with 'foo' and 'foo/bar' paths.
# 2. Remote must be present with review attribute so GitLab knows
#    where to fetch source code
module Gitlab
  module ManifestImport
    class Manifest
      attr_reader :parsed_xml, :errors

      def initialize(file)
        @parsed_xml = Nokogiri::XML(file) { |config| config.strict }
        @errors = []
      rescue Nokogiri::XML::SyntaxError
        @errors = ['The uploaded file is not a valid XML file.']
      end

      def projects
        raw_projects.each_with_index.map do |project, i|
          {
            id: i,
            name: project['name'],
            path: project['path'],
            url: repository_url(project['name'])
          }
        end
      end

      def valid?
        return false if @errors.any?

        unless validate_remote
          @errors << 'Make sure a <remote> tag is present and is valid.'
        end

        unless validate_projects
          @errors << 'Make sure every <project> tag has name and path attributes.'
        end

        unless validate_scheme
          @errors << 'Make sure the url does not start with javascript'
        end

        @errors.empty?
      end

      private

      def validate_remote
        remote.present? && URI.parse(remote).host
      rescue URI::Error
        false
      end

      def validate_projects
        raw_projects.all? do |project|
          project['name'] && project['path']
        end
      end

      def validate_scheme
        remote !~ /\Ajavascript/i
      end

      def repository_url(name)
        Gitlab::Utils.append_path(remote, name)
      end

      def remote
        return @remote if defined?(@remote)

        remote_tag = parsed_xml.css('manifest > remote').first
        @remote = remote_tag['review'] if remote_tag
      end

      def raw_projects
        @raw_projects ||= parsed_xml.css('manifest > project')
      end
    end
  end
end
