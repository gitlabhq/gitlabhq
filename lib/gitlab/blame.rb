module Gitlab
  class Blame
    attr_accessor :blob, :commit

    def initialize(blob, commit)
      @blob = blob
      @commit = commit
    end

    def groups(highlight: true)
      prev_sha = nil
      groups = []
      current_group = nil

      i = 0
      blame.each do |commit, line|
        commit = Commit.new(commit, project)

        sha = commit.sha
        if prev_sha != sha
          groups << current_group if current_group
          current_group = { commit: commit, lines: [] }
        end

        line = highlighted_lines[i].html_safe if highlight
        current_group[:lines] << line

        prev_sha = sha
        i += 1
      end
      groups << current_group if current_group

      groups
    end

    private

    def blame
      @blame ||= Gitlab::Git::Blame.new(repository, @commit.id, @blob.path)
    end

    def highlighted_lines
      @blob.load_all_data!
      @highlighted_lines ||= @blob.present.highlight.lines
    end

    def project
      commit.project
    end

    def repository
      project.repository
    end
  end
end
