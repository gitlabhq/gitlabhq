class BasePolicy
  class RuleSet
    attr_reader :can_set, :cannot_set
    def initialize(can_set, cannot_set)
      @can_set = can_set
      @cannot_set = cannot_set
    end

    def size
      to_set.size
    end

    def self.empty
      new(Set.new, Set.new)
    end

    def can?(ability)
      @can_set.include?(ability) && !@cannot_set.include?(ability)
    end

    def include?(ability)
      can?(ability)
    end

    def to_set
      @can_set - @cannot_set
    end

    def merge(other)
      @can_set.merge(other.can_set)
      @cannot_set.merge(other.cannot_set)
    end

    def can!(*abilities)
      @can_set.merge(abilities)
    end

    def cannot!(*abilities)
      @cannot_set.merge(abilities)
    end

    def freeze
      @can_set.freeze
      @cannot_set.freeze
      super
    end
  end

  def self.abilities(user, subject)
    new(user, subject).abilities
  end

  def self.class_for(subject)
    return GlobalPolicy if subject.nil?

    subject.class.ancestors.each do |klass|
      next unless klass.name

      begin
        policy_class = "#{klass.name}Policy".constantize

        # NOTE: the < operator here tests whether policy_class
        # inherits from BasePolicy
        return policy_class if policy_class < BasePolicy
      rescue NameError
        nil
      end
    end

    raise "no policy for #{subject.class.name}"
  end

  attr_reader :user, :subject
  def initialize(user, subject)
    @user = user
    @subject = subject
  end

  def abilities
    return RuleSet.empty if @user && @user.blocked?
    return anonymous_abilities if @user.nil?
    collect_rules { rules }
  end

  def anonymous_abilities
    collect_rules { anonymous_rules }
  end

  def anonymous_rules
    rules
  end

  def delegate!(new_subject)
    @rule_set.merge(Ability.allowed(@user, new_subject))
  end

  def can?(rule)
    @rule_set.can?(rule)
  end

  def can!(*rules)
    @rule_set.can!(*rules)
  end

  def cannot!(*rules)
    @rule_set.cannot!(*rules)
  end

  private

  def collect_rules(&b)
    @rule_set = RuleSet.empty
    yield
    @rule_set
  end
end
