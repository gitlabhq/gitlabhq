# frozen_string_literal: true

module ControllerWithFeatureCategory
  class Config
    attr_reader :category

    def initialize(category, only, except, if_proc, unless_proc)
      @category = category.to_sym
      @only, @except = only&.map(&:to_s), except&.map(&:to_s)
      @if_proc, @unless_proc = if_proc, unless_proc
    end

    def matches?(action)
      included?(action) && !excluded?(action) &&
        if_proc?(action) && !unless_proc?(action)
    end

    private

    attr_reader :only, :except, :if_proc, :unless_proc

    def if_proc?(action)
      if_proc.nil? || if_proc.call(action)
    end

    def unless_proc?(action)
      unless_proc.present? && unless_proc.call(action)
    end

    def included?(action)
      only.nil? || only.include?(action)
    end

    def excluded?(action)
      except.present? && except.include?(action)
    end
  end
end
