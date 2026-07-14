# frozen_string_literal: true

module Bitbucket
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
