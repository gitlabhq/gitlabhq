# frozen_string_literal: true

# See also https://github.com/python/cpython/pull/96499
module StringConversionSafety
  ConversionError = Class.new(StandardError)

  mattr_accessor :max_string_size, default: 4300

  def self.check_string_size!(str)
    return unless str.is_a?(String) && str.size > max_string_size

    raise ConversionError, "Conversion exceeds limit of #{max_string_size} (value has size of #{str.size})"
  end
end

class String
  alias_method :orig_to_i, :to_i
  def to_i(...)
    StringConversionSafety.check_string_size!(self)

    orig_to_i(...)
  end

  alias_method :orig_to_r, :to_r
  def to_r(...)
    StringConversionSafety.check_string_size!(self)

    orig_to_r(...)
  end

  alias_method :orig_to_c, :to_c
  def to_c(...)
    StringConversionSafety.check_string_size!(self)

    orig_to_c(...)
  end
end

# rubocop:disable Naming/MethodName -- overriding Ruby methods
module Kernel
  alias_method :original_integer, :Integer
  def Integer(arg, ...)
    StringConversionSafety.check_string_size!(arg)

    original_integer(arg, ...)
  end

  alias_method :original_rational, :Rational
  def Rational(arg, ...)
    StringConversionSafety.check_string_size!(arg)

    original_rational(arg, ...)
  end

  alias_method :original_complex, :Complex
  def Complex(arg, ...)
    StringConversionSafety.check_string_size!(arg)

    original_complex(arg, ...)
  end
end
# rubocop:enable Naming/MethodName
