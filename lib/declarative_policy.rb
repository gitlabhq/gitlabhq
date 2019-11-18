# frozen_string_literal: true

require_dependency 'declarative_policy/cache'
require_dependency 'declarative_policy/condition'
require_dependency 'declarative_policy/delegate_dsl'
require_dependency 'declarative_policy/policy_dsl'
require_dependency 'declarative_policy/rule_dsl'
require_dependency 'declarative_policy/preferred_scope'
require_dependency 'declarative_policy/rule'
require_dependency 'declarative_policy/runner'
require_dependency 'declarative_policy/step'

require_dependency 'declarative_policy/base'

module DeclarativePolicy
  CLASS_CACHE_MUTEX = Mutex.new
  CLASS_CACHE_IVAR = :@__DeclarativePolicy_CLASS_CACHE

  class << self
    def policy_for(user, subject, opts = {})
      cache = opts[:cache] || {}
      key = Cache.policy_key(user, subject)

      cache[key] ||=
        # to avoid deadlocks in multi-threaded environment when
        # autoloading is enabled, we allow concurrent loads,
        # https://gitlab.com/gitlab-org/gitlab-foss/issues/48263
        ActiveSupport::Dependencies.interlock.permit_concurrent_loads do
          class_for(subject).new(user, subject, opts)
        end
    end

    def class_for(subject)
      return GlobalPolicy if subject == :global
      return NilPolicy if subject.nil?

      subject = find_delegate(subject)

      policy_class = class_for_class(subject.class)
      raise "no policy for #{subject.class.name}" if policy_class.nil?

      policy_class
    end

    def has_policy?(subject)
      !class_for_class(subject.class).nil?
    end

    private

    # This method is heavily cached because there are a lot of anonymous
    # modules in play in a typical rails app, and #name performs quite
    # slowly for anonymous classes and modules.
    #
    # See https://bugs.ruby-lang.org/issues/11119
    #
    # if the above bug is resolved, this caching could likely be removed.
    def class_for_class(subject_class)
      unless subject_class.instance_variable_defined?(CLASS_CACHE_IVAR)
        CLASS_CACHE_MUTEX.synchronize do
          # re-check in case of a race
          break if subject_class.instance_variable_defined?(CLASS_CACHE_IVAR)

          policy_class = compute_class_for_class(subject_class)
          subject_class.instance_variable_set(CLASS_CACHE_IVAR, policy_class)
        end
      end

      subject_class.instance_variable_get(CLASS_CACHE_IVAR)
    end

    def compute_class_for_class(subject_class)
      subject_class.ancestors.each do |klass|
        next unless klass.name

        begin
          klass_name =
            if subject_class.respond_to?(:declarative_policy_class)
              subject_class.declarative_policy_class
            else
              "#{klass.name}Policy"
            end

          policy_class = klass_name.constantize

          # NOTE: the < operator here tests whether policy_class
          # inherits from Base. We can't use #is_a? because that
          # tests for *instances*, not *subclasses*.
          return policy_class if policy_class < Base
        rescue NameError
          nil
        end
      end

      nil
    end

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
