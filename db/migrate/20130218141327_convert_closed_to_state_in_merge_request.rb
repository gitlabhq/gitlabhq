class ConvertClosedToStateInMergeRequest < ActiveRecord::Migration
  def up
    MergeRequest.transaction do
      MergeRequest.find_each do |mr|
        if mr.closed? && mr.merged?
          mr.state = :merged
        else 
          if mr.closed? 
            mr.state = :closed
          else 
            mr.state = :opened
          end
        end

        mr.save
      end
    end
  end

  def down
    MergeRequest.transaction do
      MergeRequest.find_each do |mr|
        mr.closed = mr.closed? || mr.merged?
        mr.closed = mr.merged?
        mr.save
      end
    end
  end
end
