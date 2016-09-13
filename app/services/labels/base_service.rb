module Labels
  class BaseService
    def initialize(subject, user, params = {})
      @subject, @user, @params = subject, user, params.dup
    end

    private

    attr_reader :subject, :user, :params
  end
end
