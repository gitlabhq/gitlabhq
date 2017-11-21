class Groups::UploadsController < Groups::ApplicationController
  skip_before_action :group, if: -> { action_name == 'show' && image_or_video? }

  include UploadsActions

  private

  def show_model
    return @show_model if defined?(@show_model)

    group_id = params[:group_id]

    @show_model = Group.find_by_full_path(group_id)
  end

  alias_method :model, :group
end
