require "grit"

class GraphCommit
  attr_accessor :time, :space
  attr_accessor :refs

  def self.to_graph(project)
    @repo = project.repo
    commits = Grit::Commit.find_all(@repo, nil, {:max_count => 650})

    ref_cache = {}

    commits.map! {|c| GraphCommit.new(Commit.new(c))}
    commits.each { |commit| commit.add_refs(ref_cache, @repo) }

    days = GraphCommit.index_commits(commits)
    @days_json = days.compact.collect{|d| [d.day, d.strftime("%b")] }.to_json
    @commits_json = commits.map(&:to_graph_hash).to_json

    return @days_json, @commits_json
  end

  # Method is adding time and space on the
  # list of commits. As well as returns date list
  # corelated with time set on commits.
  #
  # @param [Array<GraphCommit>] comits to index
  #
  # @return [Array<TimeDate>] list of commit dates corelated with time on commits
  def self.index_commits(commits)
    days, heads = [], []
    map = {}

    commits.reverse.each_with_index do |c,i|
      c.time = i
      days[i] = c.committed_date
      map[c.id] = c
      heads += c.refs unless c.refs.nil?
    end

    heads.select!{|h| h.is_a? Grit::Head or h.is_a? Grit::Remote}
    # sort heads so the master is top and current branches are closer
    heads.sort! do |a,b|
      if a.name == "master"
        -1
      elsif b.name == "master"
        1
      else
        b.commit.committed_date <=> a.commit.committed_date
      end
    end

    j = 0
    heads.each do |h|
      if map.include? h.commit.id then
        j = mark_chain(j+=1, map[h.commit.id], map)
      end
    end
    days
  end

  # Add space mark on commit and its parents
  #
  # @param [Fixnum] space (row on the graph) to be set
  # @param [GraphCommit] the commit object.
  # @param [Hash<String,GraphCommit>] map of commits
  #
  # @return [Fixnum] max space used.
  def self.mark_chain(mark, commit, map)
    commit.space = mark  if commit.space == 0
    m1 = mark - 1
    marks = commit.parents.collect do |p|
      if map.include? p.id  and map[p.id].space == 0 then
        mark_chain(m1 += 1, map[p.id],map)
      else
        m1 + 1
      end
    end
    marks << mark
    marks.compact.max
  end


  def initialize(commit)
    @_commit = commit
    @time = -1
    @space = 0
  end

  def method_missing(m, *args, &block)
    @_commit.send(m, *args, &block)
  end

  def to_graph_hash
    h = {}
    h[:parents] = self.parents.collect do |p|
      [p.id,0,0]
    end
    h[:author]  = author.name
    h[:time]    = time
    h[:space]   = space
    h[:refs]    = refs.collect{|r|r.name}.join(" ") unless refs.nil?
    h[:id]      = sha
    h[:date]    = date
    h[:message] = message.force_encoding("UTF-8")
    h[:login]   = author.email
    h
  end

  def add_refs(ref_cache, repo)
    if ref_cache.empty?
      repo.refs.each do |ref|
        ref_cache[ref.commit.id] ||= []
        ref_cache[ref.commit.id] << ref
      end
    end
    @refs = ref_cache[@_commit.id] if ref_cache.include?(@_commit.id)
    @refs ||= []
  end
end
