class AvatarController < ApplicationController
  def show
    avatar_root = "public/uploads/user/avatar"
    avatar_file = Rails.root.join(avatar_root, params[:userid], params[:filename])

    if avatar_file.exist?
      send_file avatar_file.cleanpath.to_s
    else
      not_found!
    end
  end
end