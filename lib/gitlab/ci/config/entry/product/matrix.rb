# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents matrix style parallel builds.
        #
        module Product
          class Matrix < ::Gitlab::Config::Entry::Node
            include ::Gitlab::Utils::StrongMemoize
            include ::Gitlab::Config::Entry::Validatable
            include ::Gitlab::Config::Entry::Attributable

            validations do
              validates :config, array_of_hashes: true

              validate on: :composed do
                limit = Entry::Product::Parallel::PARALLEL_LIMIT

                if number_of_generated_jobs > limit
                  errors.add(:config, "generates too many jobs (maximum is #{limit})")
                end
              end
            end

            def compose!(deps = nil)
              super(deps) do
                @config.each_with_index do |variables, index|
                  @entries[index] = ::Gitlab::Config::Entry::Factory.new(Entry::Product::Variables)
                    .value(variables)
                    .with(parent: self, description: 'matrix variables definition.') # rubocop:disable CodeReuse/ActiveRecord
                    .create!
                end

                @entries.each_value do |entry|
                  entry.compose!(deps)
                end
              end
            end

            def value
              strong_memoize(:value) do
                @entries.values.map(&:value)
              end
            end

            def number_of_generated_jobs
              value.sum do |config|
                config.values.reduce(1) { |acc, values| acc * values.size }
              end
            end
          end
        end
      end
    end
  end
end
