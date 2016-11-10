class Import::BitbucketController < Import::BaseController
  before_action :verify_bitbucket_import_enabled
  before_action :bitbucket_auth, except: :callback

  rescue_from OAuth::Error, with: :bitbucket_unauthorized
  rescue_from Gitlab::BitbucketImport::Client::Unauthorized, with: :bitbucket_unauthorized

  def callback
    request_token = session.delete(:oauth_request_token)
    raise "Session expired!" if request_token.nil?

    request_token.symbolize_keys!

    access_token = client.get_token(request_token, params[:oauth_verifier], callback_import_bitbucket_url)

    session[:bitbucket_access_token] = access_token.token
    session[:bitbucket_access_token_secret] = access_token.secret

    redirect_to status_import_bitbucket_url
  end

  def status
    @repos = client.projects
    @incompatible_repos = client.incompatible_projects

    @already_added_projects = current_user.created_projects.where(import_type: "bitbucket")
    already_added_projects_names = @already_added_projects.pluck(:import_source)

    @repos.to_a.reject!{ |repo| already_added_projects_names.include? "#{repo["owner"]}/#{repo["slug"]}" }
  end

  def jobs
    jobs = current_user.created_projects.where(import_type: "bitbucket").to_json(only: [:id, :import_status])
    render json: jobs
  end

  def create
    @repo_id = params[:repo_id].to_s
    repo = client.project(@repo_id.gsub('___', '/'))
    @project_name = repo['slug']
    @target_namespace = find_or_create_namespace(repo['owner'], client.user['user']['username'])

    unless Gitlab::BitbucketImport::KeyAdder.new(repo, current_user, access_params).execute
      render 'deploy_key' and return
    end

    if current_user.can?(:create_projects, @target_namespace)
      @project = Gitlab::BitbucketImport::ProjectCreator.new(repo, @target_namespace, current_user, access_params).execute
    else
      render 'unauthorized'
    end
  end

  private

  def client
    @client ||= Gitlab::BitbucketImport::Client.new(session[:bitbucket_access_token],
                                                    session[:bitbucket_access_token_secret])
  end

  def verify_bitbucket_import_enabled
    render_404 unless bitbucket_import_enabled?
  end

  def bitbucket_auth
    if session[:bitbucket_access_token].blank?
      go_to_bitbucket_for_permissions
    end
  end

  def go_to_bitbucket_for_permissions
    request_token = client.request_token(callback_import_bitbucket_url)
    session[:oauth_request_token] = request_token

    redirect_to client.authorize_url(request_token, callback_import_bitbucket_url)
  end

  def bitbucket_unauthorized
    go_to_bitbucket_for_permissions
  end

  def access_params
    {
      bitbucket_access_token: session[:bitbucket_access_token],
      bitbucket_access_token_secret: session[:bitbucket_access_token_secret]
    }
  end
end
