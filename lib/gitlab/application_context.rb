# frozen_string_literal: true

module Gitlab
  # A GitLab-rails specific accessor for `Labkit::Logging::ApplicationContext`
  class ApplicationContext
    include Gitlab::Utils::LazyAttributes

    def self.with_context(args, &block)
      application_context = new(**args)
      Labkit::Context.with_context(application_context.to_lazy_hash, &block)
    end

    def self.push(args)
      application_context = new(**args)
      Labkit::Context.push(application_context.to_lazy_hash)
    end

    def initialize(user: nil, project: nil, namespace: nil)
      @user, @project, @namespace = user, project, namespace
    end

    def to_lazy_hash
      { user: -> { username },
        project: -> { project_path },
        root_namespace: -> { root_namespace_path } }
    end

    private

    lazy_attr_reader :user, type: User
    lazy_attr_reader :project, type: Project
    lazy_attr_reader :namespace, type: Namespace

    def project_path
      project&.full_path
    end

    def username
      user&.username
    end

    def root_namespace_path
      if namespace
        namespace.full_path_components.first
      else
        project&.full_path_components&.first
      end
    end
  end
end
