# frozen_string_literal: true

class Admin::RunnersFinder < UnionFinder
  NUMBER_OF_RUNNERS_PER_PAGE = 30

  def initialize(params:)
    @params = params
  end

  def execute
    search!
    filter_by_status!
    filter_by_runner_type!
    sort!
    paginate!

    @runners
  end

  def sort_key
    if @params[:sort] == 'contacted_asc'
      'contacted_asc'
    else
      'created_date'
    end
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
    filter_by!(:status_status, Ci::Runner::AVAILABLE_STATUSES)
  end

  def filter_by_runner_type!
    filter_by!(:type_type, Ci::Runner::AVAILABLE_TYPES)
  end

  def sort!
    @runners = @runners.order_by(sort_key)
  end

  def paginate!
    @runners = @runners.page(@params[:page]).per(NUMBER_OF_RUNNERS_PER_PAGE)
  end

  def filter_by!(scope_name, available_scopes)
    scope = @params[scope_name]

    if scope.present? && available_scopes.include?(scope)
      @runners = @runners.public_send(scope) # rubocop:disable GitlabSecurity/PublicSend
    end
  end
end
