# frozen_string_literal: true

module Gitlab
  # noinspection RubyClassModuleNamingConvention -- JetBrains is changing this to allow shorter names
  module Fp
    module RopHelpers
      # @param [Class] base
      # @return void
      def self.extended(base)
        base.class_eval do
          private_class_method :retrieve_single_public_singleton_method, :public_singleton_methods_to_ignore
        end
      end

      # @param [Class] fp_module_or_class
      # @raise [RuntimeError]
      # @return [Symbol]
      def retrieve_single_public_singleton_method(fp_module_or_class)
        fp_class_singleton_methods = fp_module_or_class.singleton_methods(false)
        public_singleton_methods = fp_class_singleton_methods - public_singleton_methods_to_ignore

        return public_singleton_methods.first if public_singleton_methods.size == 1

        fp_doc_link =
          "https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/remote_development/README.md#functional-patterns"

        rop_doc_link =
          "https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/remote_development/README.md#railway-oriented-programming-and-the-result-class"

        if public_singleton_methods.size > 1
          err_msg =
            "Railway Oriented Programming (ROP) pattern violation in class `#{fp_module_or_class}`. " \
              "Expected exactly one (1) public entry point singleton/class method to be present " \
              "in a class which is used with the ROP pattern, but " \
              "#{public_singleton_methods.size} " \
              "public singleton methods were found: #{public_singleton_methods.sort.join(', ')}. " \
              "You can make the non-entry-point method(s) private via `private_class_method :method_name`. " \
              "See #{fp_doc_link} and #{rop_doc_link} for more information."
          raise(ArgumentError, err_msg)
        end

        err_msg =
          "Railway Oriented Programming (ROP) pattern violation in class `#{fp_module_or_class}`. " \
            "Expected exactly one public entry point singleton/class method to be present " \
            "in a class which is used with the ROP pattern, but " \
            "no public singleton methods were found. " \
            "See #{fp_doc_link} and #{rop_doc_link} for more information."
        raise(ArgumentError, err_msg)
      end

      # @return [Array<Symbol>]
      def public_singleton_methods_to_ignore
        # Singleton methods added by other libraries that we need to ignore.
        Module.singleton_methods(false) + Class.singleton_methods(false)
      end
    end
  end
end
