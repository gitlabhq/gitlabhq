module Ci
  class BuildPolicy < CommitStatusPolicy
    def rules
      super

      # If we can't read build we should also not have that
      # ability when looking at this in context of commit_status
      %w(read create update admin).each do |rule|
        cannot! :"#{rule}_commit_status" unless can? :"#{rule}_build"
      end
    end
  end
end
