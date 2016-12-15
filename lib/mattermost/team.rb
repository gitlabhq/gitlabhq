module Mattermost
  class Team < Session
    # After normalization this returns an array of hashes
    #
    # [{"id"=>"paf573pj9t81urupw3fanozeda", "display_name"=>"my team", <snip>}]
    def self.all
      get('/api/v3/teams/all').parsed_response.values
    end
  end
end
