# frozen_string_literal: true

module ExportHelper
  # An EE-overwriteable list of descriptions
  def project_export_descriptions
    [
      _('Project and wiki repositories'),
      _('Project uploads'),
      _('Project configuration, excluding integrations'),
      _('Issues with comments, merge requests with diffs and comments, labels, milestones, snippets, and other project entities'),
      _('LFS objects'),
      _('Issue Boards'),
      _('Design Management files and data')
    ]
  end

  def group_export_descriptions
    [
      _('Milestones'),
      _('Labels'),
      _('Boards and Board Lists'),
      _('Badges'),
      _('Subgroups')
    ]
  end
end

ExportHelper.prepend_mod_with('ExportHelper')
