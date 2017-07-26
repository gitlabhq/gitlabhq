module Gitlab
  class ProjectTemplate
    attr_reader :title, :name

    def initialize(name, title)
      @name, @title = name, title
    end

    def logo_path
      "project_templates/#{name}.png"
    end

    def file
      template_archive.open
    end

    def template_archive
      Rails.root.join("vendor/project_templates/#{name}.tar.gz")
    end

    def ==(other)
      name == other.name && title == other.title
    end

    TemplatesTable = [
      ProjectTemplate.new('rails', 'Ruby on Rails')
    ].freeze

    class << self
      def all
        TemplatesTable
      end

      def find(name)
        all.find { |template| template.name == name.to_s }
      end
    end
  end
end
