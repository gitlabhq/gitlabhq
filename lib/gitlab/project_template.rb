# frozen_string_literal: true

module Gitlab
  class ProjectTemplate
    attr_reader :title, :name, :description, :preview, :logo

    def initialize(name, title, description, preview, logo = 'illustrations/gitlab_logo.svg')
      @name, @title, @description, @preview, @logo = name, title, description, preview, logo
    end

    def file
      archive_path.open
    end

    def archive_path
      self.class.archive_directory.join(archive_filename)
    end

    def archive_filename
      "#{name}.tar.gz"
    end

    def clone_url
      "#{preview}.git"
    end

    def project_path
      URI.parse(preview).path.sub(%r{\A/}, '')
    end

    def uri_encoded_project_path
      ERB::Util.url_encode(project_path)
    end

    def ==(other)
      name == other.name && title == other.title
    end

    TEMPLATES_TABLE = [
      ProjectTemplate.new('rails', 'Ruby on Rails', _('Includes an MVC structure, Gemfile, Rakefile, along with many others, to help you get started.'), 'https://gitlab.com/gitlab-org/project-templates/rails', 'illustrations/logos/rails.svg'),
      ProjectTemplate.new('spring', 'Spring', _('Includes an MVC structure, mvnw and pom.xml to help you get started.'), 'https://gitlab.com/gitlab-org/project-templates/spring', 'illustrations/logos/spring.svg'),
      ProjectTemplate.new('express', 'NodeJS Express', _('Includes an MVC structure to help you get started.'), 'https://gitlab.com/gitlab-org/project-templates/express', 'illustrations/logos/express.svg'),
      ProjectTemplate.new('iosswift', 'iOS (Swift)', _('A ready-to-go template for use with iOS Swift apps.'), 'https://gitlab.com/gitlab-org/project-templates/iosswift'),
      ProjectTemplate.new('dotnetcore', '.NET Core', _('A .NET Core console application template, customizable for any .NET Core project'), 'https://gitlab.com/gitlab-org/project-templates/dotnetcore', 'illustrations/logos/dotnet.svg'),
      ProjectTemplate.new('android', 'Android', _('A ready-to-go template for use with Android apps.'), 'https://gitlab.com/gitlab-org/project-templates/android', 'illustrations/logos/android.svg'),
      ProjectTemplate.new('gomicro', 'Go Micro', _('Go Micro is a framework for micro service development.'), 'https://gitlab.com/gitlab-org/project-templates/go-micro'),
      ProjectTemplate.new('hugo', 'Pages/Hugo', _('Everything you need to create a GitLab Pages site using Hugo.'), 'https://gitlab.com/pages/hugo'),
      ProjectTemplate.new('jekyll', 'Pages/Jekyll', _('Everything you need to create a GitLab Pages site using Jekyll.'), 'https://gitlab.com/pages/jekyll'),
      ProjectTemplate.new('plainhtml', 'Pages/Plain HTML', _('Everything you need to create a GitLab Pages site using plain HTML.'), 'https://gitlab.com/pages/plain-html'),
      ProjectTemplate.new('gitbook', 'Pages/GitBook', _('Everything you need to create a GitLab Pages site using GitBook.'), 'https://gitlab.com/pages/gitbook'),
      ProjectTemplate.new('hexo', 'Pages/Hexo', _('Everything you need to create a GitLab Pages site using Hexo.'), 'https://gitlab.com/pages/hexo'),
      ProjectTemplate.new('nfhugo', 'Netlify/Hugo', _('A Hugo site that uses Netlify for CI/CD instead of GitLab, but still with all the other great GitLab features.'), 'https://gitlab.com/pages/nfhugo', 'illustrations/logos/netlify.svg'),
      ProjectTemplate.new('nfjekyll', 'Netlify/Jekyll', _('A Jekyll site that uses Netlify for CI/CD instead of GitLab, but still with all the other great GitLab features.'), 'https://gitlab.com/pages/nfjekyll', 'illustrations/logos/netlify.svg'),
      ProjectTemplate.new('nfplainhtml', 'Netlify/Plain HTML', _('A plain HTML site that uses Netlify for CI/CD instead of GitLab, but still with all the other great GitLab features.'), 'https://gitlab.com/pages/nfplain-html', 'illustrations/logos/netlify.svg'),
      ProjectTemplate.new('nfgitbook', 'Netlify/GitBook', _('A GitBook site that uses Netlify for CI/CD instead of GitLab, but still with all the other great GitLab features.'), 'https://gitlab.com/pages/nfgitbook', 'illustrations/logos/netlify.svg'),
      ProjectTemplate.new('nfhexo', 'Netlify/Hexo', _('A Hexo site that uses Netlify for CI/CD instead of GitLab, but still with all the other great GitLab features.'), 'https://gitlab.com/pages/nfhexo', 'illustrations/logos/netlify.svg'),
      ProjectTemplate.new('serverless_framework', 'Serverless Framework/JS', _('A basic page and serverless function that uses AWS Lambda, AWS API Gateway, and GitLab Pages'), 'https://gitlab.com/gitlab-org/project-templates/serverless-framework', 'illustrations/logos/serverless_framework.svg')
    ].freeze

    class << self
      def all
        TEMPLATES_TABLE
      end

      def find(name)
        all.find { |template| template.name == name.to_s }
      end

      def archive_directory
        Rails.root.join("vendor/project_templates")
      end
    end
  end
end
