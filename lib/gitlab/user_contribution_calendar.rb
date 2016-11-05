module Gitlab
  class UserContributionCalendar
    def initialize(user)
      @user = user
    end

    def calculate
      query.each_with_object({}) do |(date, contributions), hash|
        hash[date] = contributions
      end
    end

    private

    def query
      UserContribution
        .where(user_id: @user.id)
        .where('date >= ?', 1.year.ago.beginning_of_day)
        .pluck(:date, :contributions)
    end
  end
end
