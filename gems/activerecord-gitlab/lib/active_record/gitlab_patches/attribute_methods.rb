# frozen_string_literal: true

if defined?(Gitlab) && ActiveRecord.version.to_s != '7.1.5.1'
  raise "This patch is only needed in Rails 7.1.5.1 for https://github.com/rails/rails/issues/51780"
end

# rubocop:disable Layout/EmptyLinesAroundAccessModifier -- This is copied directly from Rails.
# rubocop:disable Layout/IndentationWidth -- This is copied directly from Rails.
# rubocop:disable Layout/IndentationConsistency -- This is copied directly from Rails.
# rubocop:disable Style/MissingRespondToMissing -- This is copied directly from Rails.
# rubocop:disable Cop/LineBreakAroundConditionalBlock -- This is copied directly from Rails.
# rubocop:disable Style/IfUnlessModifier -- This is copied directly from Rails.
# rubocop:disable GitlabSecurity/PublicSend -- This is copied directly from Rails.
module ActiveRecord
  module AttributeMethods
    private
      def method_missing(name, ...)
        unless self.class.attribute_methods_generated?
          if self.class.method_defined?(name)
            # The method is explicitly defined in the model, but calls a generated
            # method with super. So we must resume the call chain at the right setp.
            last_method = method(name)
            last_method = last_method.super_method while last_method.super_method
            self.class.define_attribute_methods
            if last_method.super_method
              return last_method.super_method.call(...)
            end
          elsif self.class.define_attribute_methods | self.class.generate_alias_attributes
            # Some attribute methods weren't generated yet, we retry the call
            return public_send(name, ...)
          end
        end

        super
      end
  end
end
# rubocop:enable Layout/EmptyLinesAroundAccessModifier
# rubocop:enable Layout/IndentationWidth
# rubocop:enable Layout/IndentationConsistency
# rubocop:enable Style/MissingRespondToMissing
# rubocop:enable Cop/LineBreakAroundConditionalBlock
# rubocop:enable Style/IfUnlessModifier
# rubocop:enable GitlabSecurity/PublicSend
