module AdminEmailHelper
  def admin_email_grouped_recipient_options
    options_for_select([['Everyone', 'all']]) +
    grouped_options_for_select(
      'Groups' => Group.pluck(:name, :id).map{ |name, id| [name, "group-#{id}"] },
      'Projects' => grouped_project_list
    )
  end

  protected
  def grouped_project_list
    Group.includes(:projects).flat_map do |group|
      group.human_name
      group.projects.map do |project|
        ["#{group.human_name} / #{project.name}", "project-#{project.id}"]
      end
    end
  end
end