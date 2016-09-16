module Labels
  class BaseService
    def initialize(subject, user, params = {})
      @subject, @user, @params = subject, user, params.dup
    end

    private

    attr_reader :subject, :user, :params

    def find_labels(subject, label_type, title)
      Label.with_type(label_type).where(subject: subject, title: title)
    end
  end
end
