# frozen_string_literal: true

module Gitlab
  module Ci
    module Catalog
      module Bundle
        class Collector
          class IncludeFile
            class Result
              attr_reader :paths, :errors

              def initialize
                @paths = []
                @errors = []
              end

              def add_path(path)
                paths << path
              end

              def add_error(error)
                errors << error
              end
            end

            attr_reader :path, :content

            def initialize(path:, content:, include_matcher:)
              @path = path
              @content = content
              @include_matcher = include_matcher
              @result = Result.new
            end

            def execute
              if content.blank?
                add_error(content.nil? ? 'file does not exist' : 'file is empty')
              else
                parse_includes(::Gitlab::Ci::Config::Yaml::Loader.new(content).load_uninterpolated_yaml)
              end

              result
            end

            private

            attr_reader :include_matcher, :result

            def parse_includes(yaml)
              if yaml.valid?
                add_error('`spec:include` is not allowed') if yaml.spec[:include].present?

                Array.wrap(yaml.content[:include]).each { |entry| resolve(entry) }
              else
                add_error("invalid YAML: #{yaml.error}")
              end
            end

            def resolve(entry)
              entry = normalize(entry)
              file = include_matcher.process([entry]).first
              location = "#{file.include_type}: #{file.location}"
              reason = include_error(file)

              if reason
                add_error(reason, location: location)
              else
                result.add_path(file.location)
                check_rules(location, entry[:rules])
              end
            rescue ::Gitlab::Ci::Config::External::Mapper::AmbigiousSpecificationError,
              ::Gitlab::Ci::Config::External::Mapper::InvalidTypeError => e
              add_error(e.message)
            end

            def include_error(file)
              if file.include_type != :local
                "`#{file.include_type}:` includes are not allowed in a bundled component"
              elsif file.location.include?('$')
                'the location is only known when the pipeline runs, so it cannot be collected'
              elsif file.location.include?('*')
                'wildcard locations are not allowed in a bundled component'
              elsif file.invalid_extension?
                'the file does not have a YAML extension'
              end
            end

            # Inside a component, `exists:` without `project:` checks the component's own
            # repository instead of the consumer's.
            def check_rules(location, rules)
              Array.wrap(rules).each do |rule|
                next unless rule.is_a?(Hash) && rule.key?(:exists)
                next if rule[:exists].is_a?(Hash) && rule[:exists][:project].present?

                add_error('`rules:exists` must name a `project:`, such as `$CI_PROJECT_PATH`', location: location)
              end
            end

            def add_error(reason, location: nil)
              result.add_error([path, location].compact.map { |part| "`#{part}`" }.join(' includes ') + ": #{reason}")
            end

            def normalize(entry)
              case entry
              when Hash then entry.deep_symbolize_keys
              when String then ::Gitlab::UrlSanitizer.valid?(entry) ? { remote: entry } : { local: entry }
              else
                raise ::Gitlab::Ci::Config::External::Mapper::InvalidTypeError,
                  'Each include must be a hash or a string'
              end
            end
          end
        end
      end
    end
  end
end
