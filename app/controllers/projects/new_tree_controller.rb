class Projects::NewTreeController < Projects::BaseTreeController
  before_filter :require_branch_head
  before_filter :authorize_push_code!
  
  def show
  end
  
  def update
    flag = 0
    
    # replace & upload
    if params[:file_upload] != nil  
      file_na = params[:file_upload].original_filename   
      file_path = nil
      
      if file_na != nil
        file_list = tree.entries.select(&:file?)	 
        dir_list = tree.entries.select(&:dir?)
        
        # check whether current path is sub-repository
	dir_list.each do |dir|  
	
	  if dir.name != nil
            flag = 1
	  end
	end
	
	# check whether current path is sub-repository
	file_list.each do |file|  
	
	  if file.name != nil
	    flag = 1
	  end
	end
	
	# replace existing file
	if @path.match(/(.*\/)*(.+)\z/) != nil && flag == 0  	
	  flag = 2
	  params[:content] = params[:file_upload].read
	  params[:file_name] = @path	
	  file_path = @path
	  result = Files::UpdateService.new(@project, current_user, params, @ref, @path).execute
	end
	
	# upload new file
	if flag == 1 || flag == 0  		
	  flag = 3
	  
	  file_list.each do |file|
	  	
	    if file.name == file_na
	      flash[:alert] = file.name + " already exists!"
	      redirect_to project_blob_path(@project, File.join(@ref, @path))
	      return 
	    end
	  end
	  params[:content] = params[:file_upload].read
	  params[:file_name] = file_na	
	  file_path = File.join(@path, File.basename(params[:file_name]))
	  result = Files::CreateService.new(@project, current_user, params, @ref, file_path).execute
	end
      end
    end 
    
    if flag == 0
      file_path = File.join(@path, File.basename(params[:file_name]))
      result = Files::CreateService.new(@project, current_user, params, @ref, file_path).execute
    end
    
    if result[:status] == :success
      flash[:notice] = "Your changes have been successfully commited."		
      redirect_to project_blob_path(@project, File.join(@ref, file_path))
    else
      flash[:alert] = result[:message]
      render :show
    end
  end
end
