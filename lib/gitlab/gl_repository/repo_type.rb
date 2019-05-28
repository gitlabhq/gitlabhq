# frozen_string_literal: true

module Gitlab
  class GlRepository
    class RepoType
      attr_reader :name,
                  :access_checker_class,
                  :repository_accessor

      def initialize(name:, access_checker_class:, repository_accessor:)
        @name = name
        @access_checker_class = access_checker_class
        @repository_accessor = repository_accessor
      end

      def identifier_for_subject(subject)
        "#{name}-#{subject.id}"
      end

      def fetch_id(identifier)
        match = /\A#{name}-(?<id>\d+)\z/.match(identifier)
        match[:id] if match
      end

      def wiki?
        self == WIKI
      end

      def project?
        self == PROJECT
      end

      def path_suffix
        project? ? "" : ".#{name}"
      end

      def repository_for(subject)
        repository_accessor.call(subject)
      end
    end
  end
end
