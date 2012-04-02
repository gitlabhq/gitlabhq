module Event::PushTrait
  as_trait do
    def tag? 
      data[:ref]["refs/tags"]
    end

    def new_branch?
      data[:before] =~ /^00000/
    end

    def new_ref?
      data[:before] =~ /^00000/
    end

    def rm_ref?
      data[:after] =~ /^00000/
    end

    def md_ref? 
      !(rm_ref? || new_ref?)
    end

    def commit_from
      data[:before]
    end

    def commit_to
      data[:after]
    end

    def ref_name 
      if tag?
        tag_name
      else
        branch_name
      end
    end

    def branch_name
      @branch_name ||= data[:ref].gsub("refs/heads/", "")
    end

    def tag_name
      @tag_name ||= data[:ref].gsub("refs/tags/", "")
    end
  
    def commits
      @commits ||= data[:commits].map do |commit|
        project.commit(commit[:id])
      end
    end

    def ref_type
      tag? ? "tag" : "branch"
    end

    def push_action_name
      if new_ref?
        "pushed new"
      elsif rm_ref?
        "removed #{ref_type}"
      else
        "pushed to"
      end
    end

    def parent_commit
      commits.first.prev_commit
    rescue => ex
      nil
    end

    def last_commit
      commits.last
    end

    def push_with_commits? 
      md_ref? && commits.any? && parent_commit && last_commit
    end
  end
end
