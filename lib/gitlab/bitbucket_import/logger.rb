# frozen_string_literal: true

module Gitlab
  module BitbucketImport
    class Logger < ::Import::Framework::Logger
      def default_attributes
        super.merge(import_type: :bitbucket)
      end
    end
  end
end
