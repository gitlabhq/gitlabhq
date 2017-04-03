desc 'Security check via brakeman'
task :brakeman do
  # We get 0 warnings at level 'w3' but we would like to reach 'w2'. Merge
  # requests are welcome!
  if system(*%w(brakeman --no-progress --skip-files lib/backup/repository.rb -w3 -z))
    puts 'Security check succeed'
  else
    puts 'Security check failed'
    exit 1
  end
end
