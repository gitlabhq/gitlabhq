desc "GITLAB | Build internal ids for issues and merge requests"
task migrate_iids: :environment do
  puts 'Issues'.yellow
  Issue.where(iid: nil).find_each(batch_size: 100) do |issue|
    begin
      issue.set_iid
      if issue.save
        print '.'
      else
        print 'F'
      end
    rescue
      print 'F'
    end
  end

  puts 'done'
  puts 'Merge Requests'.yellow
  MergeRequest.where(iid: nil).find_each(batch_size: 100) do |mr|
    begin
      mr.set_iid
      if mr.save
        print '.'
      else
        print 'F'
      end
    rescue => ex
      print 'F'
    end
  end
end
