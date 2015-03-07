module Projects
  class BaseService < ::BaseService
    # Add an error to the project for restricted visibility levels
    def deny_visibility_level(project, denied_visibility_level = nil)
      denied_visibility_level ||= project.visibility_level

      level_name = 'Unknown'
      Gitlab::VisibilityLevel.options.each do |name, level|
        level_name = name if level == denied_visibility_level
      end

      project.errors.add(
        :visibility_level,
        "#{level_name} visibility has been restricted by your GitLab administrator"
      )
    end
  end
end
