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

    # This list of templates is for the pipeline_empty_state_templates experiment
    # and will be cleaned up with https://gitlab.com/gitlab-org/gitlab/-/issues/326299
    def experiment_suggested_ci_templates
      [
        { name: 'Android', logo: image_path('illustrations/logos/android.svg') },
        { name: 'Bash', logo: image_path('illustrations/logos/bash.svg') },
        { name: 'C++', logo: image_path('illustrations/logos/c_plus_plus.svg') },
        { name: 'Clojure', logo: image_path('illustrations/logos/clojure.svg') },
        { name: 'Composer', logo: image_path('illustrations/logos/composer.svg') },
        { name: 'Crystal', logo: image_path('illustrations/logos/crystal.svg') },
        { name: 'Dart', logo: image_path('illustrations/logos/dart.svg') },
        { name: 'Django', logo: image_path('illustrations/logos/django.svg') },
        { name: 'Docker', logo: image_path('illustrations/logos/docker.svg') },
        { name: 'Elixir', logo: image_path('illustrations/logos/elixir.svg') },
        { name: 'iOS-Fastlane', logo: image_path('illustrations/logos/fastlane.svg') },
        { name: 'Flutter', logo: image_path('illustrations/logos/flutter.svg') },
        { name: 'Go', logo: image_path('illustrations/logos/go_logo.svg') },
        { name: 'Gradle', logo: image_path('illustrations/logos/gradle.svg') },
        { name: 'Grails', logo: image_path('illustrations/logos/grails.svg') },
        { name: 'dotNET', logo: image_path('illustrations/logos/dotnet.svg') },
        { name: 'Julia', logo: image_path('illustrations/logos/julia.svg') },
        { name: 'Laravel', logo: image_path('illustrations/logos/laravel.svg') },
        { name: 'LaTeX', logo: image_path('illustrations/logos/latex.svg') },
        { name: 'Maven', logo: image_path('illustrations/logos/maven.svg') },
        { name: 'Mono', logo: image_path('illustrations/logos/mono.svg') },
        { name: 'Nodejs', logo: image_path('illustrations/logos/node_js.svg') },
        { name: 'npm', logo: image_path('illustrations/logos/npm.svg') },
        { name: 'OpenShift', logo: image_path('illustrations/logos/openshift.svg') },
        { name: 'Packer', logo: image_path('illustrations/logos/packer.svg') },
        { name: 'PHP', logo: image_path('illustrations/logos/php.svg') },
        { name: 'Python', logo: image_path('illustrations/logos/python.svg') },
        { name: 'Ruby', logo: image_path('illustrations/logos/ruby.svg') },
        { name: 'Rust', logo: image_path('illustrations/logos/rust.svg') },
        { name: 'Scala', logo: image_path('illustrations/logos/scala.svg') },
        { name: 'Swift', logo: image_path('illustrations/logos/swift.svg') },
        { name: 'Terraform', logo: image_path('illustrations/logos/terraform.svg') }
      ]
    end

    private

    def warning_markdown(pipeline)
      pipeline.warning_messages(limit: MAX_LIMIT).each do |warning|
        yield markdown(warning.content)
      end
    end
  end
end
