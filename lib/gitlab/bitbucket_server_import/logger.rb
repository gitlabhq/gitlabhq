# frozen_string_literal: true

module Gitlab
  module BitbucketServerImport
    class Logger < ::Import::Framework::Logger
      def default_attributes
        super.merge(import_type: :bitbucket_server)
      end
    end
  end
end
