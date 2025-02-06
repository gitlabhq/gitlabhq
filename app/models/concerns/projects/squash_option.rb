# frozen_string_literal: true

module Projects
  module SquashOption
    extend ActiveSupport::Concern

    included do
      enum :squash_option, { never: 0, always: 1, default_on: 2, default_off: 3 }, prefix: :squash
    end

    def human_squash_option
      case squash_option
      when 'never' then 'Do not allow'
      when 'always' then 'Require'
      when 'default_on' then 'Encourage'
      when 'default_off' then 'Allow'
      end
    end

    def squash_enabled_by_default?
      %w[always default_on].include?(squash_option)
    end

    def squash_readonly?
      %w[always never].include?(squash_option)
    end

    def branch_rule
      raise NotImplementedError
    end
  end
end
