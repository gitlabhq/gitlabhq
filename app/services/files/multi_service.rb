module Files
  class MultiService < Files::BaseService
    def create_commit!
      repository.multi_action(
        user: current_user,
        message: @commit_message,
        branch_name: @branch_name,
        actions: params[:actions],
        author_email: @author_email,
        author_name: @author_name,
        start_project: @start_project,
        start_branch_name: @start_branch
      )
    end

    private

    def validate!
      super

      params[:actions].each do |action|
        validate_action!(action)
      end
    end

    def validate_action!(action)
      unless Gitlab::Git::Index::ACTIONS.include?(action[:action].to_s)
        raise_error("Unknown action '#{action[:action]}'")
      end
    end
  end
end
