Gitlab::Seeder.quiet do
  project = Project.find_by_title('notes_sandbox')
  users = User.limit(20)
  users.each { |user| project.add_developer(user) }

  1.upto(100) do |line|
    user = users.sample
    commit_id ="ae90a6e538c8bbda7c46523dd767d3f83fb967ea"

    # Create first note
    note_type = line.even? ? "DiffNote" : "LegacyDiffNote"

    note_params = {
      noteable_type: "Commit",
      commit_id: commit_id,
      type: note_type,
      note: FFaker::Lorem.sentence,
      line_code: "0398ccd0f49298b10a3d76a47800d2ebecd49859_0_#{line}",

      position: {
        base_sha: "0000000000000000000000000000000000000000",
        start_sha: "0000000000000000000000000000000000000000",
        head_sha: "ae90a6e538c8bbda7c46523dd767d3f83fb967ea",
        old_path: "LICENSE",
        new_path: "LICENSE",
        position_type: "text",
        old_line: nil,
        new_line: line
      }.to_json
    }.with_indifferent_access

    note = Notes::CreateService.new(project, user, note_params).execute

    # Create 10 replies
    commit = project.repository.commit(commit_id)
    in_reply_to_discussion_id = note.discussion_id(commit)
    note_params[:position] = ""
    note_params[:line_code] = ""
    note_params[:in_reply_to_discussion_id] = in_reply_to_discussion_id

    5.times do
      note_params[:note] = FFaker::Lorem.sentence
      Notes::CreateService.new(project, project.users.sample, note_params).execute
    end

    print '.'
  end
end
