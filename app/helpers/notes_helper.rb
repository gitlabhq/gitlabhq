module NotesHelper
	def note_with_commit_reference(project, note)
		return '' unless note.note
		out = ''
		
		note.note.split(/([0-9a-zA-Z]{6,52})/).each do |m|
			if m =~ /^[0-9a-zA-Z]{6,52}$/
				begin
					commit = project.commit(m)
					issue_refs = commit.safe_message.scan(/#([0-9]+)/m).flatten
					link_message = issue_refs.include?(note.target.id.to_s)? commit.safe_message : m
					out += "[#{link_message}](#{project_commit_path(project,:id => commit.id)})"
				rescue
					out += m
				end
			else
				out += m
			end
		end
		preserve out
	end
end