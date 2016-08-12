class BasePolicy
  def self.abilities(user, subject)
    new(user, subject).abilities
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

  def generate!
    raise 'abstract'
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
