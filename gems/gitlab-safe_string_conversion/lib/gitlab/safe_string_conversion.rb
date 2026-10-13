# frozen_string_literal: true

require_relative "safe_string_conversion/version"

# See also https://github.com/python/cpython/pull/96499
module Gitlab
  module SafeStringConversion
    ConversionError = Class.new(StandardError)

    DISABLE_SAFETY_KEY = :gitlab_safe_string_conversion_disabled

    class << self
      attr_accessor :max_string_size
    end
    self.max_string_size = 4300

    def self.check_string_size!(str)
      return unless str.is_a?(String) && str.size > max_string_size
      return if Thread.current.thread_variable_get(DISABLE_SAFETY_KEY)

      raise ConversionError, "Conversion exceeds limit of #{max_string_size} (value has size of #{str.size})"
    end

    # Opts out of the string-size safety check for the current thread only, for
    # the duration of the block. A global opt-out would disable DoS protection
    # for all concurrently running requests, not just the one that opted out.
    def self.disable_safety
      previous = Thread.current.thread_variable_get(DISABLE_SAFETY_KEY)
      Thread.current.thread_variable_set(DISABLE_SAFETY_KEY, true)
      yield
    ensure
      Thread.current.thread_variable_set(DISABLE_SAFETY_KEY, previous)
    end
  end
end

class String
  alias_method :orig_to_i, :to_i
  def to_i(...)
    Gitlab::SafeStringConversion.check_string_size!(self)

    orig_to_i(...)
  end

  alias_method :orig_to_r, :to_r
  def to_r(...)
    Gitlab::SafeStringConversion.check_string_size!(self)

    orig_to_r(...)
  end

  alias_method :orig_to_c, :to_c
  def to_c(...)
    Gitlab::SafeStringConversion.check_string_size!(self)

    orig_to_c(...)
  end
end

# rubocop:disable Naming/MethodName -- overriding Ruby methods
module Kernel
  alias_method :original_integer, :Integer
  def Integer(arg, ...)
    Gitlab::SafeStringConversion.check_string_size!(arg)

    original_integer(arg, ...)
  end

  alias_method :original_rational, :Rational
  def Rational(arg, ...)
    Gitlab::SafeStringConversion.check_string_size!(arg)

    original_rational(arg, ...)
  end

  alias_method :original_complex, :Complex
  def Complex(arg, ...)
    Gitlab::SafeStringConversion.check_string_size!(arg)

    original_complex(arg, ...)
  end
end
# rubocop:enable Naming/MethodName
