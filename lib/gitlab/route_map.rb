module Gitlab
  class RouteMap
    class FormatError < StandardError; end

    def initialize(data)
      begin
        entries = YAML.safe_load(data)
      rescue
        raise FormatError, 'Route map needs to be valid YAML'
      end

      raise FormatError, 'Route map needs to be an array' unless entries.is_a?(Array)

      @map = entries.map { |entry| parse_entry(entry) }
    end

    def public_path_for_source_path(path)
      mapping = @map.find { |mapping| path =~ mapping[:source] }
      return unless mapping

      path.sub(mapping[:source], mapping[:public])
    end

    private

    def parse_entry(entry)
      raise FormatError, 'Route map entry needs to be a hash' unless entry.is_a?(Hash)
      raise FormatError, 'Route map entry requires a source key' unless entry.has_key?('source')
      raise FormatError, 'Route map entry requires a public key' unless entry.has_key?('public')

      source_regexp = entry['source']
      public_path = entry['public']

      unless source_regexp.start_with?('/') && source_regexp.end_with?('/')
        raise FormatError, 'Route map entry source needs to start and end in a slash (/)'
      end

      source_regexp = source_regexp[1...-1].gsub('\/', '/')

      begin
        source_regexp = Regexp.new("^#{source_regexp}$")
      rescue RegexpError => e
        raise FormatError, "Route map entry source needs to be a valid regular expression: #{e}"
      end

      {
        source: source_regexp,
        public: public_path
      }
    end
  end
end
