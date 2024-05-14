# frozen_string_literal: true

desc "GitLab | Build internal ids for issues and merge requests"
task migrate_iids: :environment do
  puts Rainbow('Issues').yellow
  Issue.where(iid: nil).find_each(batch_size: 100) do |issue|
    issue.set_iid

    if issue.update_attribute(:iid, issue.iid)
      print '.'
    else
      print 'F'
    end
  rescue StandardError
    print 'F'
  end

  puts 'done'
  puts Rainbow('Merge Requests').yellow
  MergeRequest.where(iid: nil).find_each(batch_size: 100) do |mr|
    mr.set_iid

    if mr.update_attribute(:iid, mr.iid)
      print '.'
    else
      print 'F'
    end
  rescue StandardError
    print 'F'
  end

  puts 'done'
  puts Rainbow('Milestones').yellow
  Milestone.where(iid: nil).find_each(batch_size: 100) do |m|
    m.set_iid

    if m.update_attribute(:iid, m.iid)
      print '.'
    else
      print 'F'
    end
  rescue StandardError
    print 'F'
  end

  puts 'done'
end
