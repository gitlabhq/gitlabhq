module Gitlab
  # Issues API
  class MergeRequests < Grape::API
    before { authenticate! }

    resource :projects do
      #list
      get ":id/merge_requests" do
        authorize! :read_merge_request, user_project
        
        present user_project.merge_requests, with: Entities::MergeRequest
      end
      
      #show
      get ":id/merge_request/:merge_request_id" do
        merge_request = user_project.merge_requests.find(params[:merge_request_id])
        
        authorize! :read_merge_request, merge_request
        
        present merge_request, with: Entities::MergeRequest
      end

      #create merge_request
      post ":id/merge_requests" do
        attrs = attributes_for_keys [:source_branch, :target_branch, :assignee_id, :title]
        merge_request = user_project.merge_requests.new(attrs)
        merge_request.author = current_user
        
        authorize! :write_merge_request, merge_request
        
        if merge_request.save
          merge_request.reload_code
          present merge_request, with: Entities::MergeRequest
        else
          not_found!
        end
      end

      #update merge_request
      put ":id/merge_request/:merge_request_id" do
        attrs = attributes_for_keys [:source_branch, :target_branch, :assignee_id, :title, :closed]
        merge_request = user_project.merge_requests.find(params[:merge_request_id])
        
        authorize! :modify_merge_request, merge_request
        
        if merge_request.update_attributes attrs
          merge_request.reload_code
          merge_request.mark_as_unchecked
          present merge_request, with: Entities::MergeRequest
        else
          not_found!
        end
      end

      #post comment to merge request
      post ":id/merge_request/:merge_request_id/comments" do
        merge_request = user_project.merge_requests.find(params[:merge_request_id])
        note = merge_request.notes.new(note: params[:note], project_id: user_project.id)
        note.author = current_user
        if note.save
          present note, with: Entities::Note
        else
          not_found!
        end
      end

    end
  end
end
