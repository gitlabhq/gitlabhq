# frozen_string_literal: true

module Bitbucket # rubocop:disable Gitlab/BoundedContexts -- existing module
  module Representation
    class Workspace < Representation::Base
      def slug
        raw['workspace']['slug']
      end

      def name
        raw['workspace']['name']
      end

      def uuid
        raw['workspace']['uuid']
      end
    end
  end
end
