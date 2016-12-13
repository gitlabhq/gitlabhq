module Mattermost
  class Team < Mattermost
    # After normalization this returns an array of hashes
    #
    # [{"id"=>"paf573pj9t81urupw3fanozeda", "display_name"=>"my team", <snip>}]
    def self.all
      @all_teams ||= get('/teams/all').parsed_response.values
    end
  end
end
