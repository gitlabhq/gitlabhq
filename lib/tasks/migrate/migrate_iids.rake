desc "GitLab | Build internal ids for issues and merge requests"
task migrate_iids: :environment do
  puts 'Issues'.yellow
  Issue.where(iid: nil).find_each(batch_size: 100) do |issue|
    begin
      issue.set_iid
      if issue.update_attribute(:iid, issue.iid)
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
      if mr.update_attribute(:iid, mr.iid)
        print '.'
      else
        print 'F'
      end
    rescue => ex
      print 'F'
    end
  end

  puts 'done'
  puts 'Milestones'.yellow
  Milestone.where(iid: nil).find_each(batch_size: 100) do |m|
    begin
      m.set_iid
      if m.update_attribute(:iid, m.iid)
        print '.'
      else
        print 'F'
      end
    rescue
      print 'F'
    end
  end

  puts 'done'
end
