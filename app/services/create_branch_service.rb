class CreateBranchService < BaseService
  include ActionView::Helpers::SanitizeHelper

  def execute(branch_name, ref)
    create_master_branch if project.empty_repo?

    sanitized_branch_name = sanitize_branch_name_for(branch_name)

    result = ValidateNewBranchService.new(project, current_user)
      .execute(sanitized_branch_name)

    return result if result[:status] == :error

    new_branch = repository.add_branch(current_user, sanitized_branch_name, ref)

    if new_branch
      success(branch: new_branch)
    else
      error('Invalid reference name', nil, branch_name)
    end
  rescue Gitlab::Git::HooksService::PreReceiveError => ex
    error(ex.message,  nil, branch_name)
  end

  private

  def error(message, http_status = nil, branch_name = nil)
    super(message, http_status).merge(branch_name: branch_name)
  end

  def create_master_branch
    project.repository.create_file(
      current_user,
      '/README.md',
      '',
      message: 'Add README.md',
      branch_name: 'master'
    )
  end

  def sanitize_branch_name_for(branch_name)
    Addressable::URI.unescape(sanitize(strip_tags(branch_name)))
  end
end
