desc 'Code duplication analyze via flay'
task :flay do
  output = `bundle exec flay --mass 35 app/ lib/gitlab/ 2> #{File::NULL}`

  if output.include?("Similar code found") || output.include?("IDENTICAL code found")
    puts output
    exit 1
  end
end
