Gitlab::Seeder.quiet do
  (2..20).each  do |i|
    begin
      User.seed(:id, [{
        id: i,
        username: Faker::Internet.user_name,
        name: Faker::Name.name,
        email: Faker::Internet.email,
        confirmed_at: DateTime.now
      }])
      print '.'
    rescue ActiveRecord::RecordNotSaved
      print 'F'
    end
  end

  (1..5).each do |i|
    begin
      User.seed do |s|
        s.username = "user#{i}"
        s.name = "User #{i}"
        s.email = "user#{i}@example.com"
        s.confirmed_at = DateTime.now
        s.password = '12345678'
      end
      print '.'
    rescue ActiveRecord::RecordNotSaved
      print 'F'
    end
  end
end
