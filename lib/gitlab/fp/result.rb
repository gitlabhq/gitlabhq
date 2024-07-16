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
        validate_lambda_or_singleton_method(lambda_or_singleton_method)

        # Return/passthough the Result itself if it is an err
        return self if err?

        # If the Result is ok, call the lambda or singleton method with the contained value
        result = lambda_or_singleton_method.call(value)

        unless result.is_a?(Result)
          err_msg = "'Result##{__method__}' expects a lambda or singleton method object which returns a 'Result' " \
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
        validate_lambda_or_singleton_method(lambda_or_singleton_method)

        # Return/passthrough the Result itself if it is an err
        return self if err?

        # If the Result is ok, call the lambda or singleton method with the contained value
        mapped_value = lambda_or_singleton_method.call(value)

        if mapped_value.is_a?(Result)
          err_msg = "'Result##{__method__}' expects a lambda or singleton method object which returns an unwrapped " \
            "value, not a 'Result', but instead received '#{lambda_or_singleton_method.inspect}' which returned " \
            "a 'Result'."
          raise(TypeError, err_msg)
        end

        # wrap the returned mapped_value in an "ok" Result.
        Result.ok(mapped_value)
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

      # @param [Proc, Method] lambda_or_singleton_method
      # @return [void]
      # @raise [TypeError]
      def validate_lambda_or_singleton_method(lambda_or_singleton_method)
        is_lambda = lambda_or_singleton_method.is_a?(Proc) && lambda_or_singleton_method.lambda?
        is_singleton_method =
          lambda_or_singleton_method.is_a?(Method) && lambda_or_singleton_method.owner.singleton_class?

        unless is_lambda || is_singleton_method
          err_msg = "'Result##{__method__}' expects a lambda or singleton method object, " \
            "but instead received '#{lambda_or_singleton_method.inspect}'."
          raise(TypeError, err_msg)
        end

        arity = lambda_or_singleton_method.arity

        return if arity == 1
        return if arity == -1 && lambda_or_singleton_method.source_location[0].include?('rspec')

        err_msg = "'Result##{__method__}' expects a lambda or singleton method object with a single argument " \
          "(arity of 1), but instead received '#{lambda_or_singleton_method.inspect}' with an arity of #{arity}."
        raise(ArgumentError, err_msg)
      end
    end
  end
end
