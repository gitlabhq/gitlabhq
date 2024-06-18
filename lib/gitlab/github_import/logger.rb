# frozen_string_literal: true

module Gitlab
  module GithubImport
    class Logger < ::Import::Framework::Logger
      def default_attributes
        super.merge(import_type: :github)
      end
    end
  end
end
