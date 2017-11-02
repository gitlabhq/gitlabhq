Gitlab::Seeder.quiet do
  Group.all.each do |group|
    5.times do
      epic_params = {
        title: FFaker::Lorem.sentence(6),
        description: FFaker::Lorem.paragraphs(3).join("\n\n"),
        author: group.users.sample,
        group: group
      }

      Epic.create!(epic_params)
      print '.'
    end
  end
end
