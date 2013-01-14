module Notes
  class LoadContext < BaseContext
    def execute
      target_type = params[:target_type]
      target_id   = params[:target_id]
      after_id    = params[:after_id]
      before_id   = params[:before_id]


      @notes = case target_type
               when "commit"
                 project.notes.for_commit_id(target_id).not_inline.fresh
               when "issue"
                 project.issues.find(target_id).notes.inc_author.fresh
               when "merge_request"
                 project.merge_requests.find(target_id).mr_and_commit_notes.inc_author.fresh
               when "snippet"
                 project.snippets.find(target_id).notes.fresh
               when "wall"
                 # this is the only case, where the order is DESC
                 project.notes.common.inc_author_project.order("created_at DESC, id DESC").limit(50)
               end

      @notes = if after_id
                 @notes.where("id > ?", after_id)
               elsif before_id
                 @notes.where("id < ?", before_id)
               else
                 @notes
               end
    end
  end
end
