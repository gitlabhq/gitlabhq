require 'gitlab/declarative_policy/cache'
require 'gitlab/declarative_policy/condition'
require 'gitlab/declarative_policy/dsl'
require 'gitlab/declarative_policy/preferred_scope'
require 'gitlab/declarative_policy/rule'
require 'gitlab/declarative_policy/runner'
require 'gitlab/declarative_policy/step'

require 'gitlab/declarative_policy/base'

module DeclarativePolicy
  def self.policy_for(user, subject, opts = {})
    return NilPolicy.new(user, nil, opts) if subject.nil?

    cache = opts[:cache] || {}
    user_key = Cache.user_key(user)
    subject_key = Cache.subject_key(subject)
    key = "/dp/policy/#{user_key}/#{subject_key}"

    cache[key] ||= class_for(subject).new(user, subject, opts)
  end

  def self.class_for(subject)
    return GlobalPolicy if subject == :global
    return NilPolicy if subject.nil?

    if subject.class.try(:presenter?)
      subject = subject.subject
    end

    subject.class.ancestors.each do |klass|
      next unless klass.name

      begin
        policy_class = "#{klass.name}Policy".constantize

        # NOTE: the < operator here tests whether policy_class
        # inherits from Base
        return policy_class if policy_class < Base
      rescue NameError
        nil
      end
    end

    raise "no policy for #{subject.class.name}"
  end
end
