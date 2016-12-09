class GitEnvironmentVariablesValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, env)
    variables_to_validate = %w(GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES)

    variables_to_validate.each do |variable_name|
      variable_value = env[variable_name]

      if variable_value.present? && !(variable_value =~ /^#{record.project.repository.path_to_repo}/)
        record.errors.add(attribute, "The #{variable_name} variable must start with the project repo path")
      end
    end
  end
end
