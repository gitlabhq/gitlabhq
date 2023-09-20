# frozen_string_literal: true

module API
  module Validations
    module Validators
      class GitRef < Grape::Validations::Validators::Base
        # There are few checks that a Git reference should pass through to be valid reference.
        # The link contains some rules that have been added to this validator.
        # https://mirrors.edge.kernel.org/pub/software/scm/git/docs/git-check-ref-format.html
        # We have skipped some checks that are optional and can be skipped for exception.
        # We also check for control characters, More info on ctrl chars - https://ruby-doc.org/core-2.7.0/Regexp.html#class-Regexp-label-Character+Classes
        INVALID_CHARS = Regexp.union('..', '\\', '@', '@{', ' ', '~', '^', ':', '*', '?', '[', /[[:cntrl:]]/).freeze
        GIT_REF_LENGTH = (1..1024)

        def validate_param!(attr_name, params)
          revision = params[attr_name]

          return unless invalid_character?(revision)

          raise Grape::Exceptions::Validation.new(
            params: [@scope.full_name(attr_name)],
            message: 'should be a valid reference path'
          )
        end

        private

        def invalid_character?(revision)
          revision.nil? ||
            revision.start_with?('-') ||
            revision.end_with?('.') ||
            GIT_REF_LENGTH.exclude?(revision.length) ||
            INVALID_CHARS.match?(revision)
        end
      end
    end
  end
end
