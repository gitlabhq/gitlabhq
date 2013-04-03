module Gitlab
  module Git
    class Compare
      attr_accessor :commits, :commit, :diffs, :same

      def initialize(repository, from, to)
        @commits, @diffs = [], []
        @commit = nil
        @same = false

        return unless from && to

        first = repository.commit(to.try(:strip))
        last = repository.commit(from.try(:strip))

        return unless first && last

        if first.id == last.id
          @same = true
          return
        end

        @commit = first
        @commits = repository.commits_between(last.id, first.id)

        @diffs = if @commits.size > 100
                   []
                 else
                   repository.repo.diff(last.id, first.id) rescue []
                 end
      end
    end
  end
end

