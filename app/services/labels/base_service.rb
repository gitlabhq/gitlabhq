module Labels
  class BaseService
    def initialize(subject, user, params = {})
      @subject, @user, @params = subject, user, params.dup
    end

    private

    attr_reader :subject, :user, :params

    def find_labels(subject, title)
      Label.with_type(:group_label).where(subject: subject, title: title)
    end
  end
end
