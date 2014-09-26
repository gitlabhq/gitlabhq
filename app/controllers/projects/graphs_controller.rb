class Projects::GraphsController < Projects::ApplicationController
  # Authorize
  before_filter :authorize_read_project!
  before_filter :authorize_code_access!
  before_filter :require_non_empty_project

  def show
    respond_to do |format|
      format.html
      format.json do
        fetch_graph
      end
    end
  end

  private

  def fetch_graph
    @commits = @project.repository.commits(nil, nil, 6000, 0, true)
    @log = []

    @commits.each do |commit|
      @log << {
        author_name: commit.author_name.force_encoding('UTF-8'),
        author_email: commit.author_email.force_encoding('UTF-8'),
        date: commit.committed_date.strftime("%Y-%m-%d")
      }
    end

    render json: @log.to_json
  end
end
