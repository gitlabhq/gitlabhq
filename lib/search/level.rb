# frozen_string_literal: true

module Search
  class Level
    def initialize(options)
      @options = options
    end

    def project?
      search_level == :project
    end

    def group?
      search_level == :group
    end

    def global?
      search_level == :global
    end

    def as_sym
      search_level
    end

    private

    attr_reader :options

    def search_level
      @search_level ||= if options[:project_id].present?
                          :project
                        elsif options[:group_id].present?
                          :group
                        else
                          :global
                        end
    end
  end
end
