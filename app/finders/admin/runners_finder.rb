class Admin::RunnersFinder < UnionFinder
  NUMBER_OF_RUNNERS_PER_PAGE = 30

  def initialize(params:)
    @params = params
  end

  def execute
    search!
    filter_by_status!
    sort!
    paginate!

    @runners
  end

  private

  def search!
    @runners =
      if @params[:search].present?
        Ci::Runner.search(@params[:search])
      else
        Ci::Runner.all
      end
  end

  def filter_by_status!
    status = @params[:status_status]
    if status.present? && Ci::Runner::AVAILABLE_STATUSES.include?(status)
      @runners = @runners.public_send(status) # rubocop:disable GitlabSecurity/PublicSend
    end
  end

  def sort!
    sort = @params[:sort] == 'contacted_asc' ? { contacted_at: :asc } : { id: :desc }
    @runners = @runners.order(sort)
  end

  def paginate!
    @runners = @runners.page(@params[:page]).per(NUMBER_OF_RUNNERS_PER_PAGE)
  end
end
