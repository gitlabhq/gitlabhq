# frozen_string_literal: true

module Ci
  module PipelinesHelper
    include Gitlab::Ci::Warnings

    def has_gitlab_ci?(project)
      project.has_ci? && project.builds_enabled?
    end

    def suggested_ci_templates
      [
        { name: 'Android', logo: image_path('illustrations/third-party-logos/ci_cd-template-logos/android.svg') },
        { name: 'Bash', logo: image_path('illustrations/third-party-logos/ci_cd-template-logos/bash.svg') },
        { name: 'C++', logo: image_path('illustrations/third-party-logos/ci_cd-template-logos/c_plus_plus.svg') },
        { name: 'Clojure', logo: image_path('illustrations/third-party-logos/ci_cd-template-logos/clojure.svg') },
        { name: 'Composer', logo: image_path('illustrations/third-party-logos/ci_cd-template-logos/composer.svg') },
        { name: 'Crystal', logo: image_path('illustrations/third-party-logos/ci_cd-template-logos/crystal.svg') },
        { name: 'Dart', logo: image_path('illustrations/third-party-logos/ci_cd-template-logos/dart.svg') },
        { name: 'Django', logo: image_path('illustrations/third-party-logos/ci_cd-template-logos/django.svg') },
        { name: 'Docker', logo: image_path('illustrations/third-party-logos/ci_cd-template-logos/docker.png') },
        { name: 'Elixir', logo: image_path('illustrations/third-party-logos/ci_cd-template-logos/elixir.svg') },
        { name: 'iOS-Fastlane', logo: image_path('illustrations/third-party-logos/ci_cd-template-logos/fastlane.svg'), title: 'iOS with Fastlane' },
        { name: 'Flutter', logo: image_path('illustrations/third-party-logos/ci_cd-template-logos/flutter.svg') },
        { name: 'Go', logo: image_path('illustrations/third-party-logos/ci_cd-template-logos/go_logo.svg') },
        { name: 'Gradle', logo: image_path('illustrations/third-party-logos/ci_cd-template-logos/gradle.svg') },
        { name: 'Grails', logo: image_path('illustrations/third-party-logos/ci_cd-template-logos/grails.svg') },
        { name: 'dotNET', logo: image_path('illustrations/third-party-logos/dotnet.svg') },
        { name: 'Julia', logo: image_path('illustrations/third-party-logos/ci_cd-template-logos/julia.svg') },
        { name: 'Laravel', logo: image_path('illustrations/third-party-logos/ci_cd-template-logos/laravel.svg') },
        { name: 'LaTeX', logo: image_path('illustrations/third-party-logos/ci_cd-template-logos/latex.svg') },
        { name: 'MATLAB', logo: image_path('illustrations/third-party-logos/ci_cd-template-logos/matlab.svg') },
        { name: 'Maven', logo: image_path('illustrations/third-party-logos/ci_cd-template-logos/maven.svg') },
        { name: 'Mono', logo: image_path('illustrations/third-party-logos/ci_cd-template-logos/mono.svg') },
        { name: 'Nodejs', logo: image_path('illustrations/third-party-logos/ci_cd-template-logos/node_js.svg') },
        { name: 'npm', logo: image_path('illustrations/third-party-logos/ci_cd-template-logos/npm.svg') },
        { name: 'OpenShift', logo: image_path('illustrations/third-party-logos/ci_cd-template-logos/openshift.svg') },
        { name: 'Packer', logo: image_path('illustrations/third-party-logos/ci_cd-template-logos/packer.svg') },
        { name: 'PHP', logo: image_path('illustrations/third-party-logos/ci_cd-template-logos/php.svg') },
        { name: 'Python', logo: image_path('illustrations/third-party-logos/ci_cd-template-logos/python.svg') },
        { name: 'Ruby', logo: image_path('illustrations/third-party-logos/ci_cd-template-logos/ruby.svg') },
        { name: 'Rust', logo: image_path('illustrations/third-party-logos/ci_cd-template-logos/rust.svg') },
        { name: 'Scala', logo: image_path('illustrations/third-party-logos/ci_cd-template-logos/scala.svg') },
        { name: 'Swift', logo: image_path('illustrations/third-party-logos/ci_cd-template-logos/swift.svg') },
        { name: 'Terraform', logo: image_path('illustrations/third-party-logos/ci_cd-template-logos/terraform.svg') }
      ]
    end

    def pipelines_list_data(project, list_url)
      artifacts_endpoint_placeholder = ':pipeline_artifacts_id'

      {
        endpoint: list_url,
        project_id: project.id,
        default_branch_name: project.default_branch,
        params: params.to_json,
        artifacts_endpoint: downloadable_artifacts_project_pipeline_path(project, artifacts_endpoint_placeholder, format: :json),
        artifacts_endpoint_placeholder: artifacts_endpoint_placeholder,
        pipeline_schedules_path: pipeline_schedules_path(project),
        can_create_pipeline: can?(current_user, :create_pipeline, project).to_s,
        new_pipeline_path: can?(current_user, :create_pipeline, project) && new_project_pipeline_path(project),
        reset_cache_path: can_any?(current_user, [:admin_pipeline, :admin_runner], project) && reset_cache_project_settings_ci_cd_path(project),
        has_gitlab_ci: has_gitlab_ci?(project).to_s,
        pipeline_editor_path: can?(current_user, :create_pipeline, project) && project_ci_pipeline_editor_path(project),
        suggested_ci_templates: suggested_ci_templates.to_json,
        full_path: project.full_path,
        visibility_pipeline_id_type: visibility_pipeline_id_type,
        show_jenkins_ci_prompt: show_jenkins_ci_prompt(project).to_s,
        pipelines_analytics_path: charts_project_pipelines_path(project)
      }
    end

    def visibility_pipeline_id_type
      return 'id' unless current_user.present?

      current_user.user_preference.visibility_pipeline_id_type
    end

    def new_pipeline_data(project)
      {
        project_id: project.id,
        pipelines_path: project_pipelines_path(project),
        default_branch: project.default_branch,
        pipelines_editor_path: project_ci_pipeline_editor_path(project),
        can_view_pipeline_editor: can_view_pipeline_editor?(project),
        ref_param: params[:ref] || project.default_branch,
        var_param: params[:var].to_json,
        file_param: params[:file_var].to_json,
        project_path: project.full_path,
        project_refs_endpoint: refs_project_path(project, sort: 'updated_desc'),
        settings_link: project_settings_ci_cd_path(project),
        max_warnings: ::Gitlab::Ci::Warnings::MAX_LIMIT,
        is_maintainer: can?(current_user, :maintainer_access, project)
      }
    end

    private

    def show_jenkins_ci_prompt(project)
      return false unless can?(current_user, :create_pipeline, project)
      return false if project.has_ci_config_file?

      project.repository.jenkinsfile?
    end
  end
end
