desc "GITLAB | Migrate SSH Keys"
task migrate_keys: :environment do
  puts "This will add fingerprint to ssh keys in db"
  puts "If you have duplicate keys https://github.com/gitlabhq/gitlabhq/issues/4453 all but the first will be deleted".yellow
  ask_to_continue

  Key.find_each(batch_size: 20) do |key|
    if key.valid? && key.save
      print '.'
    elsif key.fingerprint.present?
      puts "\nDeleting #{key.inspect}".yellow
      key.destroy
    else
      print 'F'
    end
  end
  print "\n"
end


