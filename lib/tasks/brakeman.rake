desc 'Security check via brakeman'
task :brakeman do
  if system("brakeman -w3 -z")
    exit 0
  else
    puts 'Security check failed'
    exit 1
  end
end
