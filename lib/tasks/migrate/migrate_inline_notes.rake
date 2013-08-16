desc "GITLAB | Migrate inline notes"
task migrate_inline_notes: :environment do
  Note.where('line_code IS NOT NULL').find_each(batch_size: 100) do |note|
    begin
      note.set_diff
      if note.save
        print '.'
      else
        print 'F'
      end
    rescue
      print 'F'
    end
  end
end

