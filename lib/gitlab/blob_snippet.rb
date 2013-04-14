module Gitlab
  class BlobSnippet
    include Linguist::BlobHelper

    attr_accessor :project
    attr_accessor :tree
    attr_accessor :lines
    attr_accessor :filename
    attr_accessor :startline
    
    def initialize(project, tree, lines, startline, filename)
      @project, @tree, @lines, @startline, @filename = project, tree, lines, startline, filename
    end
    
    def data
      lines.join("\n")
    end
    
    def name
      filename
    end
    
    def size
      data.length
    end
    
    def mode
      nil
    end
    
  end
end