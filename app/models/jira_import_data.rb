# frozen_string_literal: true

class JiraImportData < ProjectImportData
  JiraProjectDetails = Struct.new(:key, :scheduled_at, :scheduled_by)

  FORCE_IMPORT_KEY = 'force-import'

  def projects
    return [] unless data

    projects = data.dig('jira', 'projects')&.map do |p|
      JiraProjectDetails.new(p['key'], p['scheduled_at'], p['scheduled_by'])
    end

    projects&.sort_by { |jp| jp.scheduled_at } || []
  end

  def <<(project)
    self.data ||= { 'jira' => { 'projects' => [] } }
    self.data['jira'] ||= { 'projects' => [] }
    self.data['jira']['projects'] = [] if data['jira']['projects'].blank? || !data['jira']['projects'].is_a?(Array)

    self.data['jira']['projects'] << project.to_h
    self.data.deep_stringify_keys!
  end

  def force_import!
    self.data ||= {}
    self.data.deep_merge!({ 'jira' => { FORCE_IMPORT_KEY => true } })
    self.data.deep_stringify_keys!
  end

  def force_import?
    !!data&.dig('jira', FORCE_IMPORT_KEY) && !projects.blank?
  end

  def finish_import!
    return if data&.dig('jira', FORCE_IMPORT_KEY).nil?

    data['jira'].delete(FORCE_IMPORT_KEY)
  end
end
