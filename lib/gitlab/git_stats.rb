module Gitlab
  class GitStats
    attr_accessor :repo, :ref

    def initialize repo, ref
      @repo, @ref = repo, ref
    end

    def log
      @log ||= parse_log
    end

    protected

    def get_log
      args = ['--format=%aN%x0a%ad', '--date=short', '--shortstat', '--no-merges']
      log = repo.git.run(nil, 'log', nil, {}, args)
    end

    #Parses the log file into a collection of commits
    #Data model: {author, date, additions, deletions}
    def parse_log
      log = get_log.split("\n")

      i = 0
      collection = []
      entry = {}

      while i < log.size do
        pos = i % 4
        case pos
        when 0 
          unless i == 0
            collection.push(entry)
            entry = {}
          end
          entry[:author] = log[i].to_s
        when 1
          entry[:date] = log[i].to_s
        when 3
          changes = log[i].split(",")
          entry[:additions] = changes[1].to_i unless changes[1].nil?
          entry[:deletions] = changes[2].to_i unless changes[2].nil?
        end
        i += 1
      end

      collection
    end
    
  end
end
