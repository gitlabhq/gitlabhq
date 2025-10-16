# frozen_string_literal: true

module Organizations
  module Isolatable
    extend ActiveSupport::Concern

    def isolated?
      isolated_record&.isolated? || false
    end

    def not_isolated?
      !isolated?
    end

    def mark_as_isolated!
      isolation = isolated_record || build_isolated_record
      isolation.update!(isolated: true)
    end

    def mark_as_not_isolated!
      isolation = isolated_record || build_isolated_record
      isolation.update!(isolated: false)
    end
  end
end
