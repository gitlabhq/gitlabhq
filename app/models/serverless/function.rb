# frozen_string_literal: true

module Serverless
  class Function
    attr_accessor :name, :namespace

    def initialize(project, name, namespace)
      @project = project
      @name = name
      @namespace = namespace
    end

    def id
      @project.id.to_s + "/" + @name + "/" + @namespace
    end

    def self.find_by_id(id)
      array = id.split("/")
      project = Project.find_by_id(array[0])
      name = array[1]
      namespace = array[2]

      self.new(project, name, namespace)
    end
  end
end
