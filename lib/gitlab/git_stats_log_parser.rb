class LogParser
  #Parses the log file into a collection of commits
  #Data model: {author, date, additions, deletions}
  def self.parse_log log_from_git
    log = log_from_git.split("\n")

    i = 0
    collection = []
    entry = {}

    while i <= log.size do
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