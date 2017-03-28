module UsersHelper
  def user_link(user)
    link_to(user.name, user_path(user),
            title: user.email,
            class: 'has-tooltip commit-committer-link')
  end
end
