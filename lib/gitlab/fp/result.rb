# frozen_string_literal: true

# A (partial) implementation of the functional Result type, with naming conventions based on the
# Rust implementation (https://doc.rust-lang.org/std/result/index.html)
#
# Modern Ruby 3+ destructuring and pattern matching are supported.
#
# - See "Railway Oriented Programming and the Result Class" in `ee/lib/remote_development/README.md` for details
#   and example usage.
# - See `spec/lib/gitlab/fp/result_spec.rb` for detailed executable example usage.
# - See https://en.wikipedia.org/wiki/Result_type for a general description of the Result pattern.
# - See https://fsharpforfunandprofit.com/rop/ for how this can be used with Railway Oriented Programming (ROP)
#   to improve design and architecture
# - See https://doc.rust-lang.org/std/result/ for the Rust implementation.
module Gitlab
  # noinspection RubyClassModuleNamingConvention -- JetBrains is changing this to allow shorter names
  module Fp
    class Result
      # The .ok and .err factory class methods are the only way to create a Result
      #
      # "self.ok" corresponds to Ok(T) in Rust: https://doc.rust-lang.org/std/result/enum.Result.html#variant.Ok
      #
      # @param [Object, #new] ok_value
      # @return [Result]
      # noinspection MissingYardParamTag -- RubyMine does not recognize "duck type" Types
      #                                     (https://rubydoc.info/gems/yard/file/docs/Tags.md#duck-types). This has been
      #                                     reported to JetBrains - issue link pending
      def self.ok(ok_value)
        new(ok_value: ok_value)
      end

      # "self.err" corresponds to Err(E) in Rust: https://doc.rust-lang.org/std/result/enum.Result.html#variant.Err
      #
      # @param [Object, #new] err_value
      # @return [Result]
      # noinspection MissingYardParamTag -- RubyMine does not recognize "duck type" Types
      #                                     (https://rubydoc.info/gems/yard/file/docs/Tags.md#duck-types). This has been
      #                                     reported to JetBrains - issue link pending
      def self.err(err_value)
        new(err_value: err_value)
      end

      # @param [Object, nil] ok_value
      # @param [Object, nil] err_value
      # @return [Object]
      def initialize(ok_value: nil, err_value: nil)
        if (!ok_value.nil? && !err_value.nil?) || (ok_value.nil? && err_value.nil?)
          raise(ArgumentError, 'Do not directly use private constructor, use Result.ok or Result.err')
        end

        @ok = err_value.nil?
        @value = ok? ? ok_value : err_value
      end

      private :initialize

      # "#unwrap" corresponds to "unwrap" in Rust.
      #
      # @return [Object]
      # @raise [RuntimeError] if called on an "err" Result
      def unwrap
        ok? ? value : raise("Called Result#unwrap on an 'err' Result")
      end

      # "#unwrap" corresponds to "unwrap" in Rust.
      #
      # @return [Object]
      # @raise [RuntimeError] if called on an "ok" Result
      def unwrap_err
        err? ? value : raise("Called Result#unwrap_err on an 'ok' Result")
      end

      # The `ok?` attribute is true if the Result was constructed with .ok, and false if it was constructed with .err
      #
      # "#ok?" corresponds to "is_ok" in Rust.
      # @return [Boolean]
      def ok?
        # We don't make `@ok` an attr_reader, because we don't want to confusingly shadow the class method `.ok`
        @ok
      end

      # The `err?` attribute is false if the Result was constructed with .ok, and true if it was constructed with .err
      # "#err?" corresponds to "is_err" in Rust.
      #
      # @return [Boolean]
      def err?
        !ok?
      end

      # `and_then` is a functional way to chain together operations which may succeed or have errors. It is passed
      # a lambda or class (singleton) method object, and must return a Result object representing "ok"
      # or "err".
      #
      # If the Result object it is called on is "ok", then the passed lambda or singleton method
      # is called with the value contained in the Result.
      #
      # If the Result object it is called on is "err", then it is returned without calling the passed
      # lambda or method.
      #
      # It only supports being passed a lambda, or a class (singleton) method object
      # which responds to `call` with a single argument (arity of 1). If multiple values are needed,
      # pass a hash or array. Note that passing `Proc` objects is NOT supported, even though the YARD
      # annotation contains `Proc` (because the type of a lambda is also `Proc`).
      #
      # Passing instance methods to `and_then` is not supported, because the methods in the chain should be
      # stateless "pure functions", and should not be persisting or referencing any instance state anyway.
      #
      # "#and_then" corresponds to "and_then" in Rust: https://doc.rust-lang.org/std/result/enum.Result.html#method.and_then
      #
      # @param [Proc, Method] lambda_or_singleton_method
      # @return [Result]
      # @raise [TypeError]
      def and_then(lambda_or_singleton_method)
        validate_lambda_or_singleton_method(callee: lambda_or_singleton_method, invoking_method: __method__)

        # Return/passthough the Result itself if it is an err
        return self if err?

        # If the Result is ok, call the lambda or singleton method with the contained value
        result = lambda_or_singleton_method.call(value)

        unless result.is_a?(Result)
          err_msg = "Result##{__method__} expects a lambda or singleton method object which returns a 'Result' " \
            "type, but instead received '#{lambda_or_singleton_method.inspect}' which returned '#{result.class}'. " \
            "Check that the previous method calls in the '#and_then' chain are correct."
          raise(TypeError, err_msg)
        end

        result
      end

      # `map` is similar to `and_then`, but it is used for "single track" methods which always succeed,
      # and have no possibility of returning an error (but they may still raise exceptions,
      # which is unrelated to the Result handling). The passed lambda or singleton method must return
      # a value, not a Result.
      #
      # If the Result object it is called on is "ok", then the passed lambda or singleton method
      # is called with the value contained in the Result.
      #
      # If the Result object it is called on is "err", then it is returned without calling the passed
      # lambda or method.
      #
      # "#map" corresponds to "map" in Rust: https://doc.rust-lang.org/std/result/enum.Result.html#method.map
      #
      # @param [Proc, Method] lambda_or_singleton_method
      # @return [Result]
      # @raise [TypeError]
      def map(lambda_or_singleton_method)
        validate_lambda_or_singleton_method(callee: lambda_or_singleton_method, invoking_method: __method__)

        # Return/passthrough the Result itself if it is an err
        return self if err?

        # If the Result is ok, call the lambda or singleton method with the contained value
        mapped_value = lambda_or_singleton_method.call(value)

        if mapped_value.is_a?(Result)
          err_msg = "Result##{__method__} expects a lambda or singleton method object which returns an unwrapped " \
            "value, not a 'Result', but instead received '#{lambda_or_singleton_method.inspect}' which returned " \
            "a 'Result'."
          raise(TypeError, err_msg)
        end

        # wrap the returned mapped_value in an "ok" Result.
        Result.ok(mapped_value)
      end

      # `map_err` is the inverse of `map`. It behaves identically, but it only processes `err` values
      # instead of `ok` values.
      #
      # "#map_err" corresponds to "map_err" in Rust: https://doc.rust-lang.org/std/result/enum.Result.html#method.map_err
      #
      # @param [Proc, Method] lambda_or_singleton_method
      # @return [Result]
      # @raise [TypeError]
      def map_err(lambda_or_singleton_method)
        validate_lambda_or_singleton_method(callee: lambda_or_singleton_method, invoking_method: __method__)

        # Return/passthrough the Result itself if it is an ok
        return self if ok?

        # If the Result is err, call the lambda or singleton method with the contained value
        mapped_value = lambda_or_singleton_method.call(value)

        if mapped_value.is_a?(Result)
          err_msg = "Result##{__method__} expects a lambda or singleton method object which returns an unwrapped " \
            "value, not a 'Result', but instead received '#{lambda_or_singleton_method.inspect}' which returned " \
            "a 'Result'."
          raise(TypeError, err_msg)
        end

        # wrap the returned mapped_value in an "err" Result.
        Result.err(mapped_value)
      end

      # `inspect_ok` is similar to `map`, becuase it receives the wrapped `ok` value, but it does not allow modification
      # of the value like `map`. The original result is always returned from `inspect_ok`.
      #
      # The passed lambda or singleton method must return, `nil`, to enforce the fact that the return value is ignored,
      # and the original Result is always returned. This corresponds to the `void` type in YARD/RBS type annotations,
      # and the `unit` type in Rust (https://doc.rust-lang.org/std/primitive.unit.html).
      #
      # If the passed method does not return `nil`, an error will be raised.
      #
      # "#inspect_ok" corresponds to "inspect" in Rust: https://doc.rust-lang.org/std/result/enum.Result.html#method.inspect
      #
      # But note that we could not call it `inspect` here, because that would conflict with the
      # Kernel#inspect method in Ruby.
      #
      # @param [Proc, Method] lambda_or_singleton_method
      # @return [Result]
      # @raise [TypeError]
      def inspect_ok(lambda_or_singleton_method)
        validate_lambda_or_singleton_method(callee: lambda_or_singleton_method, invoking_method: __method__)

        # Return/passthrough the Result itself if it is an err
        return self if err?

        # If the Result is ok, call the lambda or singleton method with the contained value
        call_and_enforce_value_is_not_mutated(
          callee: lambda_or_singleton_method,
          value: value,
          invoking_method: __method__
        )

        # Return/passthrough the original Result
        self
      end

      # `inspect_err` is the inverse of `inspect_ok`. It behaves identically, but it only processes `err` values
      # instead of `ok` values.
      #
      # The passed lambda or singleton method must return, `nil`, to enforce the fact that the return value is ignored,
      # and the original Result is always returned. This corresponds to the `void` type in YARD/RBS type annotations,
      # and the `unit` type in Rust (https://doc.rust-lang.org/std/primitive.unit.html).
      #
      # If the passed method does not return `nil`, an error will be raised.
      #
      # "#inspect_err" corresponds to "inspect_err" in Rust: https://doc.rust-lang.org/std/result/enum.Result.html#method.inspect_err
      #
      # @param [Proc, Method] lambda_or_singleton_method
      # @return [Result]
      # @raise [TypeError]
      def inspect_err(lambda_or_singleton_method)
        validate_lambda_or_singleton_method(callee: lambda_or_singleton_method, invoking_method: __method__)

        # Return/passthrough the Result itself if it is an ok
        return self if ok?

        # If the Result is err, call the lambda or singleton method with the contained value
        call_and_enforce_value_is_not_mutated(
          callee: lambda_or_singleton_method,
          value: value,
          invoking_method: __method__
        )

        # Return/passthrough the original Result
        self
      end

      # `to_h` supports destructuring of a result object, for example: `result => { ok: }; puts ok`
      #
      # @return [Hash]
      def to_h
        ok? ? { ok: value } : { err: value }
      end

      # `deconstruct_keys` supports pattern matching on a Result object with a `case` statement. See specs for examples.
      #
      # @param [Array] keys
      # @return [Hash]
      # @raise [ArgumentError]
      def deconstruct_keys(keys)
        raise(ArgumentError, 'Use either :ok or :err for pattern matching') unless [[:ok], [:err]].include?(keys)

        to_h
      end

      # @param [Result] other
      # @return [Boolean]
      def ==(other)
        # NOTE: The underlying `@ok` instance variable is a boolean, so we only need to check `ok?`, not `err?` too
        self.class == other.class && other.ok? == ok? && other.instance_variable_get(:@value) == value
      end

      private

      # The `value` attribute will contain either the ok_value or the err_value
      #
      # @return [Object]
      # noinspection RubyMismatchedReturnType
      def value # rubocop:disable Style/TrivialAccessors -- We are not using attr_reader here, so we can avoid nilability type errors in RubyMine
        # TODO: We are not using attr_reader here, so we can avoid nilability type errors in RubyMine.
        #   This will be reported to JetBrains and tracked on
        #   https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/tracked-jetbrains-issues/,
        #   this comment should then be updated with the issue link on that page.
        #   Note that we don't use `noinspection` to suppress this error because there's several instances where
        #   this error leaks to other classes through the call stack.
        @value
      end

      # @param [Proc, Method] callee
      # @param [Symbol] invoking_method
      # @return [void]
      # @raise [TypeError]
      def validate_lambda_or_singleton_method(callee:, invoking_method:)
        is_lambda = callee.is_a?(Proc) && callee.lambda?
        is_singleton_method =
          callee.is_a?(Method) && callee.owner.singleton_class?

        unless is_lambda || is_singleton_method
          err_msg = "Result##{invoking_method} expects a lambda or singleton method object, " \
            "but instead received '#{callee.inspect}'."
          raise(TypeError, err_msg)
        end

        arity = callee.arity

        return if arity == 1
        return if arity == -1 && callee.source_location[0].include?('rspec')

        err_msg = "Result##{invoking_method} expects a lambda or singleton method object with a single argument " \
          "(arity of 1), but instead received '#{callee.inspect}' with an arity of #{arity}."
        raise(ArgumentError, err_msg)
      end

      # @param [Proc, Method] callee
      # @param [Object] value
      # @param [Symbol] invoking_method
      # @return [void]
      # @raise [RuntimeError]
      def call_and_enforce_value_is_not_mutated(callee:, value:, invoking_method:)
        value_before = value.clone

        begin
          marshalled_value_before = Marshal.dump(value)
        rescue StandardError
          # Marshal.dump will fail if there are singletons in the object
          marshalled_value_before = nil
        end

        return_value_from_call = callee.call(value)

        validate_return_value_is_void(return_value: return_value_from_call, invoking_method: invoking_method)

        begin
          marshalled_value_after = Marshal.dump(value)
        rescue StandardError
          # Marshal.dump will fail if there are singletons in the object
          marshalled_value_after = nil
        end

        value_was_mutated =
          # First do an equality check, but this might return a false positive for some deeply nested objects
          # or objects which don't implement equality properly, so also do the marshalled value equality check
          value_before != value || marshalled_value_before != marshalled_value_after

        return unless value_was_mutated

        raise "ERROR: #{callee} must not modify the passed value argument, " \
          "because it was invoked via Result##{invoking_method}"
      end

      # @param [Proc, Method] return_value
      # @param [Symbol] invoking_method
      # @return [void]
      # @raise [TypeError]
      def validate_return_value_is_void(return_value:, invoking_method:)
        return if return_value.nil?

        err_msg = "The method passed to Result##{invoking_method} must always return 'nil' (void). This enforces " \
          "that the return value is never used or modified. The existing 'Result' object is always passed along the " \
          "chain unchanged. The return value received was '#{return_value.inspect}' instead of 'nil'."
        raise(TypeError, err_msg)
      end
    end
  end
end
