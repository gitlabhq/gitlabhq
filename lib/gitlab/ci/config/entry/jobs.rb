module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a set of jobs.
        #
        class Jobs < Node
          include Validatable

          validations do
            validates :config, type: Hash

            validate do
              unless has_visible_job?
                errors.add(:config, 'should contain at least one visible job')
              end
            end

            def has_visible_job?
              config.any? { |name, _| !hidden?(name) }
            end
          end

          def hidden?(name)
            name.to_s.start_with?('.')
          end

          # rubocop: disable CodeReuse/ActiveRecord
          def compose!(deps = nil)
            super do
              @config = @config.map do |name, config|
                total = config[:parallel]
                if total
                  Array.new(total) { { name => config } }
                    .each_with_index { |build, idx| build["#{name} #{idx + 1}/#{total}".to_sym] = build.delete(name) }
                else
                  { name => config }
                end
              end.flatten.reduce(:merge)

              @config.each do |name, config|
                node = hidden?(name) ? Entry::Hidden : Entry::Job

                factory = Entry::Factory.new(node)
                  .value(config || {})
                  .metadata(name: name)
                  .with(key: name, parent: self,
                        description: "#{name} job definition.")

                @entries[name] = factory.create!
              end

              @entries.each_value do |entry|
                entry.compose!(deps)
              end
            end
          end
          # rubocop: enable CodeReuse/ActiveRecord
        end
      end
    end
  end
end
