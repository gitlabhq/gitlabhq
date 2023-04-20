# frozen_string_literal: true

module Ci
  module PipelinesHelper
    include Gitlab::Ci::Warnings

    def pipeline_warnings(pipeline)
      return unless pipeline.warning_messages.any?

      total_warnings = pipeline.warning_messages.length
      message = warning_header(total_warnings)

      content_tag(:div, class: 'bs-callout bs-callout-warning') do
        content_tag(:details) do
          concat content_tag(:summary, message, class: 'gl-mb-2')
          warning_markdown(pipeline) { |markdown| concat markdown }
        end
      end
    end

    def warning_header(count)
      message = _("%{total_warnings} warning(s) found:") % { total_warnings: count }

      return message unless count > MAX_LIMIT

      _("%{message} showing first %{warnings_displayed}") % { message: message, warnings_displayed: MAX_LIMIT }
    end

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

    def has_pipeline_badges?(pipeline)
      pipeline.schedule? ||
        pipeline.child? ||
        pipeline.latest? ||
        pipeline.merge_train_pipeline? ||
        pipeline.has_yaml_errors? ||
        pipeline.failure_reason? ||
        pipeline.auto_devops_source? ||
        pipeline.detached_merge_request_pipeline? ||
        pipeline.stuck?
    end

    def pipelines_list_data(project, list_url)
      artifacts_endpoint_placeholder = ':pipeline_artifacts_id'

      data = {
        endpoint: list_url,
        project_id: project.id,
        default_branch_name: project.default_branch,
        params: params.to_json,
        artifacts_endpoint: downloadable_artifacts_project_pipeline_path(project, artifacts_endpoint_placeholder, format: :json),
        artifacts_endpoint_placeholder: artifacts_endpoint_placeholder,
        pipeline_schedule_url: pipeline_schedules_path(project),
        empty_state_svg_path: image_path('illustrations/pipelines_empty.svg'),
        error_state_svg_path: image_path('illustrations/pipelines_failed.svg'),
        no_pipelines_svg_path: image_path('illustrations/pipelines_pending.svg'),
        can_create_pipeline: can?(current_user, :create_pipeline, project).to_s,
        new_pipeline_path: can?(current_user, :create_pipeline, project) && new_project_pipeline_path(project),
        ci_lint_path: can?(current_user, :create_pipeline, project) && project_ci_lint_path(project),
        reset_cache_path: can?(current_user, :admin_pipeline, project) && reset_cache_project_settings_ci_cd_path(project),
        has_gitlab_ci: has_gitlab_ci?(project).to_s,
        pipeline_editor_path: can?(current_user, :create_pipeline, project) && project_ci_pipeline_editor_path(project),
        suggested_ci_templates: suggested_ci_templates.to_json,
        full_path: project.full_path
      }

      experiment(:ios_specific_templates, actor: current_user, project: project, sticky_to: project) do |e|
        e.candidate do
          data[:registration_token] = project.runners_token if can?(current_user, :register_project_runners, project)
          data[:ios_runners_available] = (project.shared_runners_available? && Gitlab.com?).to_s
        end
      end

      data
    end

    private

    def warning_markdown(pipeline)
      pipeline.warning_messages(limit: MAX_LIMIT).each do |warning|
        yield markdown(warning.content)
      end
    end
  end
end
