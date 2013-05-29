desc "GITLAB | Migrate Note LineCode"
task migrate_note_linecode: :environment do
  Note.inline.each do |note|
    index = note.diff_file_index
    if index =~ /^\d{1,10}$/ # is number. not hash.
      hash = Digest::SHA1.hexdigest(note.noteable.diffs[index.to_i].new_path)
      new_line_code = note.line_code.sub(index, hash)
      note.update_column :line_code, new_line_code
      print '.'
    end
  end
end

