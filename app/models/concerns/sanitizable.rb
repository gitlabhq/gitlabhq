# frozen_string_literal: true

# == Sanitizable concern
#
# This concern adds HTML sanitization and validation to models. The intention is
# to help prevent XSS attacks in the event of a by-pass in the frontend
# sanitizer due to a configuration issue or a vulnerability in the sanitizer.
# This approach is commonly referred to as defense-in-depth.
#
# Example:
#
# module Dast
#   class Profile < ApplicationRecord
#     include Sanitizable
#
#     sanitizes! :name, :description

module Sanitizable
  extend ActiveSupport::Concern

  class_methods do
    def sanitize(input)
      return unless input

      # We return the input unchanged to avoid escaping pre-escaped HTML fragments.
      # Please see gitlab-org/gitlab#293634 for an example.
      return input unless input == CGI.unescapeHTML(input.to_s)

      CGI.unescapeHTML(Sanitize.fragment(input))
    end

    def sanitizes!(*attrs)
      instance_eval do
        before_validation do
          attrs.each do |attr|
            input = public_send(attr) # rubocop: disable GitlabSecurity/PublicSend

            public_send("#{attr}=", self.class.sanitize(input)) # rubocop: disable GitlabSecurity/PublicSend
          end
        end

        validates_each(*attrs) do |record, attr, input|
          # We reject pre-escaped HTML fragments as invalid to avoid saving them
          # to the database.
          unless input.to_s == CGI.unescapeHTML(input.to_s)
            record.errors.add(attr, 'cannot contain escaped HTML entities')
          end

          # This method raises an exception on failure so perform this
          # last if multiple errors should be returned.
          Gitlab::PathTraversal.check_path_traversal!(input.to_s)

        rescue Gitlab::Utils::DoubleEncodingError
          record.errors.add(attr, 'cannot contain escaped components')
        rescue Gitlab::PathTraversal::PathTraversalAttackError
          record.errors.add(attr, "cannot contain a path traversal component")
        end
      end
    end
  end
end
