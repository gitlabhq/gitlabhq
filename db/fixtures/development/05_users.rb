Gitlab::Seeder.quiet do
  (2..20).each  do |i|
    begin
      User.create!(
        username: FFaker::Internet.user_name,
        name: FFaker::Name.name,
        email: FFaker::Internet.email,
        confirmed_at: DateTime.now,
        password: '12345678'
      )

      print '.'
    rescue ActiveRecord::RecordInvalid
      print 'F'
    end
  end

  (1..5).each do |i|
    begin
      User.create!(
        username: "user#{i}",
        name: "User #{i}",
        email: "user#{i}@example.com",
        confirmed_at: DateTime.now,
        password: '12345678'
      )
      print '.'
    rescue ActiveRecord::RecordInvalid
      print 'F'
    end
  end
end
