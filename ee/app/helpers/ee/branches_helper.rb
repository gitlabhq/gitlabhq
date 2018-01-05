module EE
  module BranchesHelper
    # Returns a hash were keys are types of access levels (user, role), and
    # values are the number of access levels of the particular type.
    def access_level_frequencies(access_levels)
      access_levels.each_with_object(Hash.new(0)) do |access_level, frequencies|
        frequencies[access_level.type] += 1
      end
    end

    def access_levels_data(access_levels)
      access_levels.map do |level|
        if level.type == :user
          {
            id: level.id,
            type: level.type,
            user_id: level.user_id,
            username: level.user.username,
            name: level.user.name,
            avatar_url: level.user.avatar_url
          }
        elsif level.type == :group
          { id: level.id, type: level.type, group_id: level.group_id }
        else
          { id: level.id, type: level.type, access_level: level.access_level }
        end
      end
    end
  end
end
