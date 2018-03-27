# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Representation
      module ExposeAttribute
        extend ActiveSupport::Concern

        module ClassMethods
          # Defines getter methods for the given attribute names.
          #
          # Example:
          #
          #     expose_attribute :iid, :title
          def expose_attribute(*names)
            names.each do |name|
              name = name.to_sym

              define_method(name) { attributes[name] }
            end
          end
        end
      end
    end
  end
end
