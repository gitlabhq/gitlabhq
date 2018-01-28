class Projects::LfsLocksApiController < Projects::GitHttpClientController
  include LfsRequest

  def create
    @result = Lfs::LockFileService.new(project, user, params).execute

    render_json(@result[:lock])
  end

  def unlock
    @result = Lfs::UnlockFileService.new(project, user, params).execute

    render_json(@result[:lock])
  end

  def index
    @result = Lfs::LocksFinderService.new(project, user, params).execute

    render_json(@result[:locks])
  end

  def verify
    @result = Lfs::LocksFinderService.new(project, user, {}).execute

    ours, theirs = split_by_owner(@result[:locks])

    render_json({ ours: ours, theirs: theirs }, false)
  end

  private

  def render_json(data, process = true)
    render json: build_payload(data, process),
           content_type: LfsRequest::CONTENT_TYPE,
           status: @result[:http_status]
  end

  def build_payload(data, process)
    data = LfsFileLockSerializer.new.represent(data) if process

    return data if @result[:status] == :success

    # When the locking failed due to an existent Lock, the existent record
    # is returned in `@result[:lock]`
    error_payload(@result[:message], @result[:lock] ? data : {})
  end

  def error_payload(message, custom_attrs = {})
    custom_attrs.merge({
      message: message,
      documentation_url: help_url
    })
  end

  def split_by_owner(locks)
    groups = locks.partition { |lock| lock.user_id == user.id }

    groups.map! do |records|
      LfsFileLockSerializer.new.represent(records, root: false)
    end
  end

  def download_request?
    params[:action] == 'index'
  end

  def upload_request?
    %w(create unlock verify).include?(params[:action])
  end
end
