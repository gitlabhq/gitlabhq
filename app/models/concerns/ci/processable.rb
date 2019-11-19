# frozen_string_literal: true

module Ci
  ##
  # This module implements methods that need to be implemented by CI/CD
  # entities that are supposed to go through pipeline processing
  # services.
  #
  #
  module Processable
    extend ActiveSupport::Concern

    included do
      has_many :needs, class_name: 'Ci::BuildNeed', foreign_key: :build_id, inverse_of: :build

      accepts_nested_attributes_for :needs
    end

    def schedulable?
      raise NotImplementedError
    end

    def action?
      raise NotImplementedError
    end

    def when
      read_attribute(:when) || 'on_success'
    end

    def expanded_environment_name
      raise NotImplementedError
    end

    def scoped_variables_hash
      raise NotImplementedError
    end
  end
end
