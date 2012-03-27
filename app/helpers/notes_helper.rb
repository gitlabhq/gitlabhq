module NotesHelper
	def note_with_commit_reference(project, note)
		return '' unless note.note
		out = ''
		
		if note.note =~ /^[0-9a-zA-Z]{6,52}$/
			begin
				commit = project.commit(note.note)
				issue_refs = commit.safe_message.scan(/#([0-9]+)/m).flatten
				if issue_refs.include?(note.target.id)
					out += link_to(commit.safe_message, project_commit_path(project,commit))
				else
					out += link_to(note.note, project_commit_path(project,commit))
				end
			rescue
				out += note.note
			end
		else
			out = note.note
		end
		preserve out
	end
end