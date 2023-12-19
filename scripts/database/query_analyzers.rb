# frozen_string_literal: true

require 'yaml'

class Database
  class QueryAnalyzers
    attr_reader :analyzers

    def initialize
      config = YAML.safe_load_file(File.expand_path('query_analyzers.yml', __dir__))
      @analyzers = self.class.all.map do |subclass|
        subclass_name = subclass.to_s.split('::').last
        subclass.new(config[subclass_name])
      end
    end

    def analyze(query)
      analyzers.each { |analyzer| analyzer.analyze(query) }
    end

    def save!
      analyzers.each(&:save!)
    end

    class << self
      def all
        ObjectSpace.each_object(::Class).select { |c| c < Base }
      end
    end
  end
end

Dir[File.join(File.expand_path('query_analyzers', __dir__), '*.rb')].each do |plugin|
  require plugin
end
