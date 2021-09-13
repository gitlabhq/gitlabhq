# frozen_string_literal: true

module BulkImports
  class Stage
    def self.pipelines
      new.pipelines
    end

    def pipelines
      @pipelines ||= config
        .values
        .sort_by { |entry| entry[:stage] }
        .map do |entry|
          [entry[:stage], entry[:pipeline]]
        end
    end

    private

    def config
      # To be implemented in a sub-class
      NotImplementedError
    end
  end
end
