class IssueContenToNote < ActiveRecord::Migration
  def up
    puts "Issue content is deprecated -> move to notes"
    Issue.find_each(:batch_size => 100) do |issue|
      next if issue.content.blank?
      note = Note.new(
        :note => issue.content,
        :project_id => issue.project_id,
        :noteable => issue,
        :created_at => issue.created_at,
        :updated_at => issue.created_at
      )
      note.author_id = issue.author_id

      if note.save
        issue.update_attributes(:content => nil)
        print "."
      else
        print "F"
      end
    end

    total = Issue.where("content is not null").count

    if total > 0
      puts "content of #{total} issues were not migrated"
    else
      puts "Done"
    end
  end

  def down
  end
end
