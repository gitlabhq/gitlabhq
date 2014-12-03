class Projects::NewTreeController < Projects::BaseTreeController
  before_filter :require_branch_head
  before_filter :authorize_push_code!

  def show
  end

  def update

    if @path.match(/(.*\/)*(.+)\z/)!=nil
      file_na=@path.match(/(.*\/)*(.+)\z/)[2]
      @path=@path.gsub(file_na,'')
      params[:content]=params[:file_upload].read
      params[:file_name]=file_na
    end
    
    file_path = File.join(@path, File.basename(params[:file_name]))
    result = Files::CreateService.new(@project, current_user, params, @ref, file_path).execute

    if result[:status] == :success
      flash[:notice] = "Your changes have been successfully committed"
      redirect_to project_blob_path(@project, File.join(@ref, file_path))
    else
      flash[:alert] = result[:message]
      render :show
    end
  end
end
