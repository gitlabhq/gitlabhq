require 'digest/crc32'

module Composer
  class Package
    include ActiveModel::Serializers::JSON

    attr_reader :name, :description, :type, :version, :version_normalized, :uid, :source, :dist, :homepage, :keywords, :time

    def initialize(project, ref, mode="default", defaults={})
      @project, @ref, @mode, @defaults = project, ref, mode, defaults

      if mode == "default"

        cjson = project.repository.blob_at(ref.target, "composer.json")
        @properties = ActiveSupport::JSON.decode(cjson.data) if cjson
        raise "build package error" unless @properties

      elsif mode == "project"

        @properties = {}
        if defaults.key?("type")
          @properties["type"] = defaults["type"]
        end

      elsif mode == "advanced"

        @properties = defaults
        raise "build package error" unless @properties

      else

        raise 'invalid package mode error'

      end

    end

    def attributes
      atts = {
        "name" => name,
        "description" => description,
        "version" => version,
        "version_normalized" => version_normalized,
        "uid" => uid,
        "source" => source,
        "dist" => dist,
      }
      atts["type"] = type unless type && type.empty?
      atts["homepage"] = homepage unless homepage.empty?
      atts["keywords"] = keywords unless keywords.empty?
      return atts
    end

    def name
      if @properties.key?("name")
        @properties["name"]
      else
        project.path_with_namespace.gsub(/\s/, '').downcase
      end
    end

    def description
      if @properties.key?("description")
        @properties["description"]
      else
        project.description
      end
    end

    def type
      if @properties.key?("type")
        @properties["type"]
      end
    end

    def version
      (ref.instance_of?(Gitlab::Git::Branch)) ? "dev-#{ref.name}" : ref.name
    end

    def version_normalized
      normalize(version)
    end

    def uid
      Digest::CRC32.checksum(ref.name + ref.target)
    end

    def source
      {
        "url" => project.url_to_repo,
        "type" => "git",
        "reference" => ref.target
      }
    end

    def dist
      {
        "url" => [project.web_url, 'repository', 'archive.zip?ref=' + ref.name].join('/'),
        "type" => "zip"
      }
    end

    def homepage
      if @properties.key?("homepage")
        @properties["homepage"]
      else
        project.web_url
      end
    end

    def keywords
      if @properties.key?("keywords")
        @properties["keywords"]
      else
        project.tags.collect { |t| t["name"] }
      end
    end

    def time
      # Iterate the project's events looking for any events pertaining to the specific target we're interested in
      project.events.each do |e|
        begin
          return e.created_at.strftime('%Y-%m-%d %H:%M:%S') if e.commit_to === ref.target
        rescue
          # If there's a problem, just skip the "time" field
        end
      end
    end

    # PRIVATE METHODS
    private

    def project
      @project
    end

    def ref
      @ref
    end

    def data
      @raw
    end

    # based on https://github.com/composer/composer/blob/master/src/Composer/Package/Version/VersionParser.php
    def normalize(ver)
      modifier_regex = '[._-]?(?:(stable|beta|b|RC|alpha|a|patch|pl|p)(?:[.-]?(\d+))?)?([.-]?dev)?'
      stability = {
        'a' => 'alpha',
        'b' => 'beta',
        'p' => 'patch',
        'p1' => 'patch',
        'rc' => 'RC'
      }

      ver.strip!

      # Ignore aliases and just assume the alias is required instead of the source
      if matches = /^([^,\s]+) +as +([^,\s]+)$/.match(ver)
        ver = matches[1]
      end

      # Match master-like branches
      return '9999999-dev' if /^(?:dev-)?(?:master|trunk|default)$/i.match(ver)

      return "dev-#{ver[4 .. ver.size]}" if ver[0 ... 4] === 'dev-'

      # Match classical versioning
      index = 0
      if matches = /^v?(\d{1,3})(\.\d+)?(\.\d+)?(\.\d+)?#{modifier_regex}$/i.match(ver)
        ver = ''
        matches.to_a[1 .. 4].each do |c|
          ver += c ? c : '.0'
        end
        index = 5
      elsif matches = /^v?(\d{4}(?:[.:-]?\d{2}){1,6}(?:[.:-]?\d{1,3})?)#{modifier_regex}$/i.match(ver)
        ver = matches[1].gsub(/\D/, '-')
        index = 2
      elsif matches = /^v?(\d{4,})(\.\d+)?(\.\d+)?(\.\d+)?#{modifier_regex}$/i.match(ver)
        ver = ''
        matches.to_a[1 .. 4].each do |c|
          ver += c ? c : '.0'
        end
        index = 5
      end

      # Add version modifiers if a version was matched
      if index > 0
        if matches[index]
          return ver if matches[index] === 'stable'

          stab = stability[matches[index]]
          ver = "#{ver}-#{stab ? stab : matches[index]}#{matches[index + 1] ? matches[index + 1] : ''}"
        end

        if matches[index + 2]
          ver = "#{ver}-dev"
        end

        return ver
      end

      # Match dev branches
      if matches = /(.*?)[.-]?dev$/i.match(ver)
        begin
          return normalize_branch(match[1])
        rescue
        end
      end

      raise 'Invalid version string'

    end

    def normalize_branch(name)
      name.strip!

      if ['master', 'trunk', 'default'].include? name
        return normalize(name)
      end

      if matches = /^v?(\d+)(\.(?:\d+|[x*]))?(\.(?:\d+|[x*]))?(\.(?:\d+|[x*]))?$/i.match(name)
        ver = ''

        [1..4].each do |i|
          ver = "#{ver}#{matches[i] ? matches[i].gsub('*', 'x') : '.x'}"
        end

        return "#{ver.gsub('x', '9999999')}-dev"
      end

      return "dev-#{name}"
    end

    def log(message)
      Gitlab::AppLogger.error("COMPOSER-PACKAGE: #{message}")
    end
  end
end