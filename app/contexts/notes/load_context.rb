module Notes
  class LoadContext < BaseContext
    def execute
      target_type = params[:target_type]
      target_id   = params[:target_id]
      after_id    = params[:after_id]


      @notes = case target_type
               when "commit"
                 project.commit_notes(project.commit(target_id)).fresh.limit(20)
               when "issue"
                 project.issues.find(target_id).notes.inc_author.fresh.limit(20)
               when "merge_request"
                 project.merge_requests.find(target_id).notes.inc_author.fresh.limit(20)
               when "snippet"
                 project.snippets.find(target_id).notes.fresh
               when "wall"
                 # this is the only case, where the order is DESC
                 project.common_notes.order("created_at DESC").limit(50)
               when "wiki"
                 project.wikis.reverse.map {|w| w.notes.fresh }.flatten[0..20]
               end

      @notes = if after_id
                 @notes.where("id > ?", after_id)
               else 
                 @notes
               end
    end
  end
end
