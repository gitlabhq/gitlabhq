class BasePolicy
  def initialize(user, subject)
    @user = user
    @subject = subject
  end

  def abilities
    @can = Set.new
    @cannot = Set.new
    generate!
    @can - @cannot
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
end
