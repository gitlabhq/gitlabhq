class DeleteUserService
  def execute(user)
    if user.solo_owned_groups.present?
      user.errors[:base] << 'You must transfer ownership or delete groups before you can remove user'
      user
    else
      # TODO: Skip remove repository so Namespace#rm_dir works
      user.personal_projects.each do |project|
        ::Projects::DestroyService.new(project, current_user, {}).execute
      end

      user.destroy
    end
  end
end
