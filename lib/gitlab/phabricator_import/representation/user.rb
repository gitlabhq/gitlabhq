# frozen_string_literal: true

module Gitlab
  module PhabricatorImport
    module Representation
      class User
        def initialize(json)
          @json = json
        end

        def phabricator_id
          json['phid']
        end

        def username
          json['fields']['username']
        end

        private

        attr_reader :json
      end
    end
  end
end
