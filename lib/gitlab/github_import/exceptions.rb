# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Exceptions
      # Sometimes it's not clear which of not implemented interfaces  caused this error.
      # We need custom exception to be able to add text that gives extra context.
      NotImplementedError = Class.new(StandardError)

      NoteableNotFound = Class.new(StandardError)
    end
  end
end
