# frozen_string_literal: true

module Gitlab
  class ProjectTemplate
    attr_reader :title, :name, :description, :preview, :logo

    def initialize(name, title, description, preview, logo = 'illustrations/gitlab_logo.svg')
      @name = name
      @title = title
      @description = description
      @preview = preview
      @logo = logo
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

    def project_host
      return unless preview

      uri = URI.parse(preview)
      uri.path = ""
      uri.to_s
    end

    def project_path
      URI.parse(preview).path.delete_prefix('/')
    end

    def uri_encoded_project_path
      ERB::Util.url_encode(project_path)
    end

    def ==(other)
      name == other.name && title == other.title
    end

    class << self
      # TODO: Review child inheritance of this table (see: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/41699#note_430928221)
      def localized_templates_table
        [
          ProjectTemplate.new('rails', 'Ruby on Rails', _('Includes an MVC structure, Gemfile, Rakefile, along with many others, to help you get started'), 'https://gitlab.com/gitlab-org/project-templates/rails', 'illustrations/logos/rails.svg'),
          ProjectTemplate.new('spring', 'Spring', _('Includes an MVC structure, mvnw and pom.xml to help you get started'), 'https://gitlab.com/gitlab-org/project-templates/spring', 'illustrations/logos/spring.svg'),
          ProjectTemplate.new('express', 'NodeJS Express', _('Includes an MVC structure to help you get started'), 'https://gitlab.com/gitlab-org/project-templates/express', 'illustrations/logos/express.svg'),
          ProjectTemplate.new('dotnetcore', '.NET Core', _('A .NET Core console application template, customizable for any .NET Core project'), 'https://gitlab.com/gitlab-org/project-templates/dotnetcore', 'illustrations/third-party-logos/dotnet.svg'),
          ProjectTemplate.new('android', 'Android', _('A ready-to-go template for use with Android apps'), 'https://gitlab.com/gitlab-org/project-templates/android', 'illustrations/logos/android.svg'),
          ProjectTemplate.new('astro', 'Pages/Astro', _('Template for GitLab Pages and Astro. Astro is a static site generator written in JavaScript.'), 'https://gitlab.com/pages/astro', 'illustrations/third-party-logos/astro.svg'),
          ProjectTemplate.new('docusaurus', 'Pages/Docusaurus', _('Template for GitLab Pages and Docusaurus. Docusaurus is a static site generator written in React.'), 'https://gitlab.com/pages/docusaurus'),
          ProjectTemplate.new('hugo', 'Pages/Hugo', _('Template for GitLab Pages and Hugo. Hugo is a static site generator written in Go.'), 'https://gitlab.com/pages/hugo', 'illustrations/logos/hugo.svg'),
          ProjectTemplate.new('jekyll', 'Pages/Jekyll', _('Template for GitLab Pages and Jekyll. Jekyll is a static site generator written in Ruby.'), 'https://gitlab.com/pages/jekyll', 'illustrations/logos/jekyll.svg'),
          ProjectTemplate.new('nextjs', 'Pages/Next.js', _('Template for GitLab Pages and Next.js. Next.js is a React framework for building web applications.'), 'https://gitlab.com/pages/nextjs'),
          ProjectTemplate.new('nuxt', 'Pages/Nuxt', _('Template for GitLab Pages and Nuxt. Nuxt is a Vue framework for building web applications.'), 'https://gitlab.com/pages/nuxt', 'illustrations/third-party-logos/nuxt.svg'),
          ProjectTemplate.new('plainhtml', 'Pages/Plain HTML', _('Template for GitLab Pages using plain HTML, CSS, and JavaScript.'), 'https://gitlab.com/pages/plain-html'),
          ProjectTemplate.new('cluster_management', 'GitLab Cluster Management', _('An example project for managing Kubernetes clusters integrated with GitLab'), 'https://gitlab.com/gitlab-org/project-templates/cluster-management'),
          ProjectTemplate.new('typo3_distribution', 'TYPO3 Distribution', _('A template for starting a new TYPO3 project'), 'https://gitlab.com/gitlab-org/project-templates/typo3-distribution', 'illustrations/logos/typo3.svg'),
          ProjectTemplate.new('nist_80053r5', 'NIST 800-53r5', _('A project containing issues for security and privacy controls published by the U.S. National Institute of Standards and Technology'), 'https://gitlab.com/gitlab-org/project-templates/nist_80053r5'),
          ProjectTemplate.new('gitlab_components', 'GitLab CI/CD components', _('A basic folder structure and sample files for a CI/CD components project.'), 'https://gitlab.com/gitlab-org/project-templates/gitlab-component-template')
        ]
      end

      def all
        localized_templates_table
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

Gitlab::ProjectTemplate.prepend_mod_with('Gitlab::ProjectTemplate')
