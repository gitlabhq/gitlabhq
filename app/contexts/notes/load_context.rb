module Notes
  class LoadContext < BaseContext
    def execute
      target_type = params[:target_type]
      target_id   = params[:target_id]
      first_id    = params[:first_id]
      last_id     = params[:last_id]


      @notes = case target_type
               when "commit" 
                 then project.commit_notes(project.commit(target_id)).fresh.limit(20)
               when "snippet"
                 then  project.snippets.find(target_id).notes
               when "wall"
                 then project.common_notes.order("created_at DESC").fresh.limit(50)
               when "issue"
                 then project.issues.find(target_id).notes.inc_author.order("created_at DESC").limit(20)
               when "merge_request"
                 then project.merge_requests.find(target_id).notes.inc_author.order("created_at DESC").limit(20)
               when "wiki"
                 then project.wikis.reverse.map {|w| w.notes.fresh }.flatten[0..20]
               end

      @notes = if last_id
                 @notes.where("id > ?", last_id)
               elsif first_id
                 @notes.where("id < ?", first_id)
               else 
                 @notes
               end
    end
  end
end
