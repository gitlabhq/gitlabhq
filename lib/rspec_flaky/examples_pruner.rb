require 'json'

module RspecFlaky
  class ExamplesPruner
    # - flaky_examples: contains flaky examples
    attr_reader :flaky_examples

    def initialize(collection)
      unless collection.is_a?(RspecFlaky::FlakyExamplesCollection)
        raise ArgumentError, "`collection` must be a RspecFlaky::FlakyExamplesCollection, #{collection.class} given!"
      end

      @flaky_examples = collection
    end

    def prune_examples_older_than(date)
      updated_hash = flaky_examples.dup
        .delete_if do |uid, hash|
          hash[:last_flaky_at] && Time.parse(hash[:last_flaky_at]).to_i < date.to_i
        end

      RspecFlaky::FlakyExamplesCollection.new(updated_hash)
    end
  end
end
