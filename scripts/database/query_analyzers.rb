# frozen_string_literal: true

class Database
  class QueryAnalyzers
    attr_reader :analyzers

    def initialize
      @analyzers = ObjectSpace.each_object(::Class).select { |c| c < Base }.map(&:new)
    end

    def analyze(query)
      analyzers.each { |analyzer| analyzer.analyze(query) }
    end

    def save!
      analyzers.each(&:save!)
    end
  end
end

Dir[File.join(File.expand_path('query_analyzers', __dir__), '*.rb')].each do |plugin|
  require plugin
end
