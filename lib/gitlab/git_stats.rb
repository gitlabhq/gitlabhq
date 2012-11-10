module Gitlab
  class GitStats
    attr_accessor :repo, :ref

    def initialize repo, ref
      @repo, @ref = repo, ref
    end

    def authors
      @authors ||= collect_authors
    end

    def commits_count
      @commits_count ||= repo.commit_count(ref)
    end

    def files_count
      repo.git.sh("git ls-tree -r --name-only #{ref} | wc -l").first.to_i
    end

    def authors_count
      authors.size
    end

    def graph
      @graph ||= build_graph
    end

    protected

    def collect_authors
      shortlog = repo.git.shortlog({e: true, s: true }, ref)

      authors = []

      lines = shortlog.split("\n")

      lines.each do |line|
        data = line.split("\t")
        commits = data.first
        author = Grit::Actor.from_string(data.last)

        authors << OpenStruct.new(
          name: author.name,
          email: author.email,
          commits: commits.to_i
        )
      end

      authors.sort_by(&:commits).reverse
    end

    def build_graph n = 4
      from, to = (Date.today - n.weeks), Date.today

      format = "--pretty=format:'%h|%at|%ai|%aE'"
      commits_strings = repo.git.sh("git rev-list --since #{from.to_s(:date)} #{format} #{ref} | grep -v commit")[0].split("\n")

      commits_dates = commits_strings.map do |string|
        data = string.split("|")
        date = data[2]
        Time.parse(date).to_date.to_s(:date)
      end

      commits_per_day = from.upto(to).map do |day|
        commits_dates.count(day.to_date.to_s(:date))
      end

      OpenStruct.new(
        labels: from.upto(to).map { |day| day.stamp('Aug 23') },
        commits: commits_per_day,
        weeks: n
      )
    end
  end
end
