module Project::HooksTrait
  as_trait do
    def observe_push(oldrev, newrev, ref, author_key_id)
      data = web_hook_data(oldrev, newrev, ref, author_key_id)

      Event.create(
        :project => self,
        :action => Event::Pushed,
        :data => data,
        :author_id => data[:user_id]
      )
    end

    def update_merge_requests(oldrev, newrev, ref, author_key_id)
      return true unless ref =~ /heads/
      branch_name = ref.gsub("refs/heads/", "")
      user = Key.find_by_identifier(author_key_id).user
      c_ids = self.commits_between(oldrev, newrev).map(&:id)

      # Update code for merge requests
      mrs = self.merge_requests.opened.find_all_by_branch(branch_name).all
      mrs.each { |merge_request| merge_request.reload_code }

      # Close merge requests
      mrs = self.merge_requests.opened.where(:target_branch => branch_name).all
      mrs = mrs.select(&:last_commit).select { |mr| c_ids.include?(mr.last_commit.id) } 
      mrs.each { |merge_request| merge_request.merge!(user.id) }

      true
    end

    def execute_web_hooks(oldrev, newrev, ref, author_key_id)
      ref_parts = ref.split('/')

      # Return if this is not a push to a branch (e.g. new commits)
      return if ref_parts[1] !~ /heads/ || oldrev == "00000000000000000000000000000000"

      data = web_hook_data(oldrev, newrev, ref, author_key_id)

      web_hooks.each { |web_hook| web_hook.execute(data) }
    end

    def web_hook_data(oldrev, newrev, ref, author_key_id)
      key = Key.find_by_identifier(author_key_id)
      data = {
        before: oldrev,
        after: newrev,
        ref: ref,
        user_id: key.user.id,
        user_name: key.user_name,
        repository: {
          name: name,
          url: web_url,
          description: description,
          homepage: web_url,
          private: private?
        },
        commits: []
      }

      commits_between(oldrev, newrev).each do |commit|
        data[:commits] << {
          id: commit.id,
          message: commit.safe_message,
          timestamp: commit.date.xmlschema,
          url: "http://#{GIT_HOST['host']}/#{code}/commits/#{commit.id}",
          author: {
            name: commit.author_name,
            email: commit.author_email
          }
        }
      end

      data
    end
  end
end
