class BasePolicy
  def self.abilities(user, subject)
    new(user, subject).abilities
  end

  def self.class_for(subject)
    "#{subject.class.name}Policy".constantize
  end

  attr_reader :user, :subject
  def initialize(user, subject)
    @user = user
    @subject = subject
  end

  def abilities
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
    @can.merge(BasePolicy.class_for(new_subject).abilities(@user, new_subject))
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
    return Set.new if @subject.nil?

    @can = Set.new
    @cannot = Set.new
    yield
    @can - @cannot
  end
end
