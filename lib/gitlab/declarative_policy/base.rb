module DeclarativePolicy
  class Base
    class AbilityMap
      attr_reader :map
      def initialize(map = {})
        @map = map
      end

      def merge(other)
        conflict_proc = proc { |key, my_val, other_val| my_val + other_val }
        AbilityMap.new(@map.merge(other.map, &conflict_proc))
      end

      def actions(key)
        @map[key] ||= []
      end

      def enable(key, rule)
        actions(key) << [:enable, rule]
      end

      def prevent(key, rule)
        actions(key) << [:prevent, rule]
      end
    end

    class << self
      def own_ability_map
        @own_ability_map ||= AbilityMap.new
      end

      def ability_map
        if self == Base
          own_ability_map
        else
          superclass.ability_map.merge(own_ability_map)
        end
      end

      def own_conditions
        @own_conditions ||= {}
      end

      def conditions
        if self == Base
          own_conditions
        else
          superclass.conditions.merge(own_conditions)
        end
      end

      def own_global_actions
        @own_global_actions ||= []
      end

      def global_actions
        if self == Base
          own_global_actions
        else
          superclass.global_actions + own_global_actions
        end
      end

      def own_delegations
        @own_delegations ||= []
      end

      def delegations
        if self == Base
          own_delegations
        else
          superclass.delegations + own_delegations
        end
      end

      def delegate(&delegation_block)
        own_delegations << delegation_block
      end

      def configuration_for(ability)
        ability_map.actions(ability) + global_actions
      end

      def enable_when(abilities, rule)
        abilities.each { |a| own_ability_map.enable(a, rule) }
      end

      def prevent_when(abilities, rule)
        abilities.each { |a| own_ability_map.prevent(a, rule) }
      end

      def prevent_all_when(rule)
        own_global_actions << [:prevent, rule]
      end

      def rule(&b)
        rule = RuleDsl.new(self).instance_eval(&b)
        PolicyDsl.new(self, rule)
      end

      def user_conditions(&b)
        old_value
      end

      def desc(description)
        @last_description = description
      end

      def condition(name, opts = {}, &value)
        name = name.to_sym
        description, @last_description = @last_description, nil
        opts[:context_key] ||= self.name
        condition = Condition.new(name, description, opts, &value)

        self.own_conditions[name] = condition
        interrog_name = :"#{name}?"

        define_method(interrog_name) { condition(name).pass? }
      end
    end

    def can?(ability, new_subject = :_self)
      return allowed?(ability) if new_subject == :_self

      other_policy = DeclarativePolicy.policy_for(user, new_subject, cache: @cache)

      other_policy.allowed?(ability)
    end

    def allowed?(*abilities)
      abilities.all? { |a| runner(a).pass? }
    end

    def disallowed?(*abilities)
      abilities.all? { |a| !runner(a).pass? }
    end

    def debug(ability, *a)
      runner(ability).debug(*a)
    end

    attr_reader :user, :subject
    def initialize(user, subject, opts = {})
      @user = user
      @subject = subject
      @cache = opts[:cache] || {}
    end

    desc "Unknown user"
    condition(:anonymous, score: 0) { @user.nil? }

    desc "By default"
    condition(:default, score: 0) { true }

    def repr
      subject_repr =
        if @subject.respond_to?(:id)
          "#{@subject.class.name}/#{@subject.id}"
        else
          @subject.inspect
        end

      user_repr =
        if @user
          "@#{@user.username}"
        else
          "<anonymous>"
        end

      "(#{user_repr} : #{subject_repr})"
    end

    def inspect
      "#<#{self.class.name} #{repr}>"
    end

    def runner(ability)
      ability = ability.to_sym
      @runners ||= {}
      @runners[ability] ||=
        begin
          delegated_runners = delegated_policies.map { |p| p.runner(ability) }
          own_runner = Runner.new(own_steps(ability))
          delegated_runners.inject(own_runner, &:merge_runner)
        end
    end

    # NOTE we can't use ||= here because the value might be the
    # boolean `false`
    def cache(key, &b)
      return @cache[key] if cached?(key)
      @cache[key] = yield
    end

    def cached?(key)
      @cache[key] != nil
    end

    def condition(name)
      name = name.to_sym
      @_conditions ||= {}
      @_conditions[name] ||=
        begin
          raise "invalid condition #{name}" unless self.class.conditions.key?(name)
          ManifestCondition.new(self.class.conditions[name], self)
        end
    end

    def banned?
      global_steps = self.class.global_actions.map { |(action, rule)| Step.new(self, rule, action) }
      !Runner.new(global_steps).pass?
    end

    protected

    def own_steps(ability)
      rules = self.class.configuration_for(ability)
      rules.map { |(action, rule)| Step.new(self, rule, action) }
    end

    def delegated_policies
      @delegated_policies ||= self.class.delegations.map do |d|
        new_subject = instance_eval(&d)

        # never delegate to nil, as that would immediately prevent_all
        next if new_subject.nil?

        DeclarativePolicy.policy_for(@user, new_subject, cache: @cache)
      end.compact
    end
  end
end
