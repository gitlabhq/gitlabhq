class Import::GoogleCodeController < Import::BaseController

  def new
    
  end

  def callback
    dump_file = params[:dump_file]

    unless dump_file.respond_to?(:read)
      return redirect_to :back, alert: "You need to upload a Google Takeout JSON file."
    end

    begin
      dump = JSON.parse(dump_file.read)
    rescue
      return redirect_to :back, alert: "The uploaded file is not a valid Google Takeout JSON file."
    end

    unless Gitlab::GoogleCodeImport::Client.new(dump).valid?
      return redirect_to :back, alert: "The uploaded file is not a valid Google Takeout JSON file."
    end

    session[:google_code_dump] = dump
    redirect_to status_import_google_code_path
  end

  def status
    unless client.valid?
      return redirect_to new_import_google_path 
    end

    @repos = client.repos

    @already_added_projects = current_user.created_projects.where(import_type: "google_code")
    already_added_projects_names = @already_added_projects.pluck(:import_source)

    @repos.reject! { |repo| already_added_projects_names.include? repo.name }
  end

  def jobs
    jobs = current_user.created_projects.where(import_type: "google_code").to_json(only: [:id, :import_status])
    render json: jobs
  end

  def create
    @repo_id = params[:repo_id]
    repo = client.repo(@repo_id)
    @target_namespace = current_user.namespace
    @project_name = repo.name

    namespace = @target_namespace

    @project = Gitlab::GoogleCodeImport::ProjectCreator.new(repo, namespace, current_user).execute
  end

  private

  def client
    @client ||= Gitlab::GoogleCodeImport::Client.new(session[:google_code_dump])
  end

end
