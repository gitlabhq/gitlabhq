module EpicsHelper
  def epic_meta_data
    author = @epic.author

    data = {
      created: @epic.created_at,
      author: {
        name: author.name,
        url: user_path(author),
        username: "@#{author.username}",
        src: avatar_icon(@epic.author)
      },
      start_date: @epic.start_date,
      end_date: @epic.end_date
    }

    data.to_json
  end
end
