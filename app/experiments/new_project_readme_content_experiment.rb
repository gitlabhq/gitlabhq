# frozen_string_literal: true

class NewProjectReadmeContentExperiment < ApplicationExperiment # rubocop:disable Gitlab/NamespacedClass
  TEMPLATE_PATH = Rails.root.join('app', 'experiments', 'templates', 'new_project_readme_content')

  def run_with(project, variant: nil)
    @project = project
    record!
    run(variant)
  end

  def control_behavior
    template('readme_basic.md')
  end

  def advanced_behavior
    template('readme_advanced.md')
  end

  private

  def template(name)
    ERB.new(File.read(TEMPLATE_PATH.join("#{name}.tt")), trim_mode: '<>').result(binding)
  end
end
