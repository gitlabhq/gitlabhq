require_dependency 'declarative_policy/cache'
require_dependency 'declarative_policy/condition'
require_dependency 'declarative_policy/dsl'
require_dependency 'declarative_policy/preferred_scope'
require_dependency 'declarative_policy/rule'
require_dependency 'declarative_policy/runner'
require_dependency 'declarative_policy/step'

require_dependency 'declarative_policy/base'

module DeclarativePolicy
  class << self
    def policy_for(user, subject, opts = {})
      cache = opts[:cache] || {}
      key = Cache.policy_key(user, subject)

      cache[key] ||= class_for(subject).new(user, subject, opts)
    end

    def class_for(subject)
      return GlobalPolicy if subject == :global
      return NilPolicy if subject.nil?

      subject = find_delegate(subject)

      subject.class.ancestors.each do |klass|
        next unless klass.name

        begin
          policy_class = "#{klass.name}Policy".constantize

          # NOTE: the < operator here tests whether policy_class
          # inherits from Base. We can't use #is_a? because that
          # tests for *instances*, not *subclasses*.
          return policy_class if policy_class < Base
        rescue NameError
          nil
        end
      end

      raise "no policy for #{subject.class.name}"
    end

    private

    def find_delegate(subject)
      seen = Set.new

      while subject.respond_to?(:declarative_policy_delegate)
        raise ArgumentError, "circular delegations" if seen.include?(subject.object_id)
        seen << subject.object_id
        subject = subject.declarative_policy_delegate
      end

      subject
    end
  end
end
