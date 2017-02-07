module Gitlab
  class RouteMap
    class FormatError < StandardError; end

    def initialize(data)
      begin
        entries = YAML.safe_load(data)
      rescue
        raise FormatError, 'Route map is not valid YAML'
      end

      raise FormatError, 'Route map is not an array' unless entries.is_a?(Array)

      @map = entries.map { |entry| parse_entry(entry) }
    end

    def public_path_for_source_path(path)
      mapping = @map.find { |mapping| mapping[:source] === path }
      return unless mapping

      path.sub(mapping[:source], mapping[:public])
    end

    private

    def parse_entry(entry)
      raise FormatError, 'Route map entry is not a hash' unless entry.is_a?(Hash)
      raise FormatError, 'Route map entry does not have a source key' unless entry.has_key?('source')
      raise FormatError, 'Route map entry does not have a public key' unless entry.has_key?('public')

      source_pattern = entry['source']
      public_path = entry['public']

      if source_pattern.start_with?('/') && source_pattern.end_with?('/')
        source_pattern = source_pattern[1...-1].gsub('\/', '/')

        begin
          source_pattern = /\A#{source_pattern}\z/
        rescue RegexpError => e
          raise FormatError, "Route map entry source is not a valid regular expression: #{e}"
        end
      end

      {
        source: source_pattern,
        public: public_path
      }
    end
  end
end
