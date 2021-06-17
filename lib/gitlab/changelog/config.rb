# frozen_string_literal: true

module Gitlab
  module Changelog
    # Configuration settings used when generating changelogs.
    class Config
      # When rendering changelog entries, authors are not included.
      AUTHORS_NONE = 'none'

      # The path to the configuration file as stored in the project's Git
      # repository.
      FILE_PATH = '.gitlab/changelog_config.yml'

      # The default date format to use for formatting release dates.
      DEFAULT_DATE_FORMAT = '%Y-%m-%d'

      # The default template to use for generating release sections.
      DEFAULT_TEMPLATE = File.read(File.join(__dir__, 'template.tpl'))

      # The regex to use for extracting the version from a Git tag.
      #
      # This regex is based on the official semantic versioning regex (as found
      # on https://semver.org/), with the addition of allowing a "v" at the
      # start of a tag name.
      #
      # We default to a strict regex as we simply don't know what kind of data
      # users put in their tags. As such, using simpler patterns (e.g. just
      # `\d+` for the major version) could lead to unexpected results.
      #
      # We use a String here as `Gitlab::UntrustedRegexp` is a mutable object.
      DEFAULT_TAG_REGEX = '^v?(?P<major>0|[1-9]\d*)' \
        '\.(?P<minor>0|[1-9]\d*)' \
        '\.(?P<patch>0|[1-9]\d*)' \
        '(?:-(?P<pre>(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))' \
        '?(?:\+(?P<meta>[0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$'

      attr_accessor :date_format, :categories, :template, :tag_regex

      def self.from_git(project)
        if (yaml = project.repository.changelog_config)
          from_hash(project, YAML.safe_load(yaml))
        else
          new(project)
        end
      end

      def self.from_hash(project, hash)
        config = new(project)

        if (date = hash['date_format'])
          config.date_format = date
        end

        if (template = hash['template'])
          config.template =
            begin
              TemplateParser::Parser.new.parse_and_transform(template)
            rescue TemplateParser::Error => e
              raise Error, e.message
            end
        end

        if (categories = hash['categories'])
          if categories.is_a?(Hash)
            config.categories = categories
          else
            raise Error, 'The "categories" configuration key must be a Hash'
          end
        end

        if (regex = hash['tag_regex'])
          config.tag_regex = regex
        end

        config
      end

      def initialize(project)
        @project = project
        @date_format = DEFAULT_DATE_FORMAT
        @template =
          begin
            TemplateParser::Parser.new.parse_and_transform(DEFAULT_TEMPLATE)
          rescue TemplateParser::Error => e
            raise Error, e.message
          end
        @categories = {}
        @tag_regex = DEFAULT_TAG_REGEX
      end

      def contributor?(user)
        @project.team.contributor?(user)
      end

      def category(name)
        @categories[name] || name
      end

      def format_date(date)
        date.strftime(@date_format)
      end
    end
  end
end
