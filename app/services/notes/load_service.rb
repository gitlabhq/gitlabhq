module Notes
  class LoadService < BaseService
    def execute
      target_type = params[:target_type]
      target_id   = params[:target_id]


      @notes = case target_type
               when "commit"
                 project.notes.for_commit_id(target_id).not_inline.fresh
               when "issue"
                 project.issues.find(target_id).notes.inc_author.fresh
               when "merge_request"
                 project.merge_requests.find(target_id).mr_and_commit_notes.inc_author.fresh
               when "snippet"
                 project.snippets.find(target_id).notes.fresh
               end
    end
  end
end
