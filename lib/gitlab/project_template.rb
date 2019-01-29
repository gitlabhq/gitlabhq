# frozen_string_literal: true

module Gitlab
  class ProjectTemplate
    attr_reader :title, :name, :description, :preview

    def initialize(name, title, description, preview)
      @name, @title, @description, @preview = name, title, description, preview
    end

    alias_method :logo, :name

    def file
      archive_path.open
    end

    def archive_path
      Rails.root.join("vendor/project_templates/#{name}.tar.gz")
    end

    def clone_url
      "https://gitlab.com/gitlab-org/project-templates/#{name}.git"
    end

    def ==(other)
      name == other.name && title == other.title
    end

    TEMPLATES_TABLE = [
      ProjectTemplate.new('rails', 'Ruby on Rails', _('Includes an MVC structure, Gemfile, Rakefile, along with many others, to help you get started.'), 'https://gitlab.com/gitlab-org/project-templates/rails'),
      ProjectTemplate.new('spring', 'Spring', _('Includes an MVC structure, mvnw and pom.xml to help you get started.'), 'https://gitlab.com/gitlab-org/project-templates/spring'),
      ProjectTemplate.new('express', 'NodeJS Express', _('Includes an MVC structure to help you get started.'), 'https://gitlab.com/gitlab-org/project-templates/express'),
      ProjectTemplate.new('hugo', 'Pages/Hugo', _('Everything you need to create a GitLab Pages site using Hugo.'), 'https://gitlab.com/pages/hugo'),
      ProjectTemplate.new('jekyll', 'Pages/Jekyll', _('Everything you need to create a GitLab Pages site using Jekyll.'), 'https://gitlab.com/pages/jekyll'),
      ProjectTemplate.new('plainhtml', 'Pages/Plain HTML', _('Everything you need to create a GitLab Pages site using plain HTML.'), 'https://gitlab.com/pages/plain-html'),
      ProjectTemplate.new('gitbook', 'Pages/GitBook', _('Everything you need to create a GitLab Pages site using GitBook.'), 'https://gitlab.com/pages/gitbook'),
      ProjectTemplate.new('hexo', 'Pages/Hexo', _('Everything you need to create a GitLab Pages site using Hexo.'), 'https://gitlab.com/pages/hexo')
    ].freeze

    class << self
      def all
        TEMPLATES_TABLE
      end

      def find(name)
        all.find { |template| template.name == name.to_s }
      end

      def archive_directory
        Rails.root.join("vendor_directory/project_templates")
      end
    end
  end
end
