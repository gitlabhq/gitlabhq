desc "GITLAB | Migrate SSH Keys"
task migrate_keys: :environment do
  puts "This will add fingerprint to ssh keys in db"
  ask_to_continue

  Key.find_each(batch_size: 20) do |key|
    if key.valid? && key.save
      print '.'
    else
      print 'F'
    end
  end
end


