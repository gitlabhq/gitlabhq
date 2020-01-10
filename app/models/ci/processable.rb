# frozen_string_literal: true

module Ci
  class Processable < ::CommitStatus
    has_many :needs, class_name: 'Ci::BuildNeed', foreign_key: :build_id, inverse_of: :build

    accepts_nested_attributes_for :needs

    scope :preload_needs, -> { preload(:needs) }

    validates :type, presence: true

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
