class BasePolicy
  def self.abilities(user, subject)
    new(user, subject).abilities
  end

  def self.class_for(subject)
    return GlobalPolicy if subject.nil?

    subject.class.ancestors.each do |klass|
      next unless klass.name

      begin
        policy_class = "#{klass.name}Policy".constantize

        # NB: the < operator here tests whether policy_class
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
    return [] if @user && @user.blocked?
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
    @can.merge(Ability.allowed(@user, new_subject))
  end

  def can?(rule)
    @can.include?(rule) && !@cannot.include?(rule)
  end

  def can!(*rules)
    @can.merge(rules)
  end

  def cannot!(*rules)
    @cannot.merge(rules)
  end

  private

  def collect_rules(&b)
    @can = Set.new
    @cannot = Set.new
    yield
    @can - @cannot
  end
end
