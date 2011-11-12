require "grit"

class GraphCommit
  attr_accessor :time, :space
  def initialize(commit)
    @_commit = commit
    @time = -1
    @space = 0
  end

  def method_missing(m, *args, &block)
    @_commit.send(m, *args, &block)
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
      days[i]=c.committed_date 
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
        mark_chain(m1+=1, map[p.id],map) 
      else
        m1 + 1
      end
    end
    marks << mark
    marks.compact.max
  end
  
  def self.add_refs(commit, ref_cache)
    if ref_cache.empty?
      @repo.refs.each {|ref| ref_cache[ref.commit.id] ||= [];ref_cache[ref.commit.id] << ref}
    end
    commit.refs = ref_cache[commit.id] if ref_cache.include? commit.id
    commit.refs ||= []
  end
end
