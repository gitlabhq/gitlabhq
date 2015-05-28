class DeleteUserService
  def execute(user)
    if user.solo_owned_groups.present?
      user.errors[:base] << 'You must transfer ownership or delete groups before you can remove user'
      user
    else
      user.destroy
    end
  end
end
