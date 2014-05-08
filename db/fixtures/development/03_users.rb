Gitlab::Seeder.quiet do
  (2..10).each  do |i|
    begin
      user = User.seed(:id, [{
        id: i,
        username: Faker::Internet.user_name,
        password: 'a' * 8,
        name: Faker::Name.name,
        email: Faker::Internet.email,
        confirmed_at: DateTime.now
      }])
      print '.'
    rescue ActiveRecord::RecordNotSaved
      print 'F'
    end
  end

  if Settings.gitlab.include_predictable_data
    (1..20).each do |i|
      begin
        user = User.seed(:email, [{
          email: "user#{i}@mail.com",
          username: "user#{i}",
          password: 'a' * 8,
          name: "User#{i}",
          confirmed_at: DateTime.now
        }])
        print '.'
      rescue ActiveRecord::RecordNotSaved
        print 'F'
      end
    end
  end
end
