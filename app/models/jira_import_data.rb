# frozen_string_literal: true

class JiraImportData < ProjectImportData
  JiraProjectDetails = Struct.new(:key, :scheduled_at, :scheduled_by)

  def projects
    return [] unless data

    projects = data.dig('jira', 'projects').map do |p|
      JiraProjectDetails.new(p['key'], p['scheduled_at'], p['scheduled_by'])
    end
    projects.sort_by { |jp| jp.scheduled_at }
  end

  def <<(project)
    self.data ||= { jira: { projects: [] } }
    self.data['jira']['projects'] << project.to_h.deep_stringify_keys!
  end
end
