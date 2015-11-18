desc 'Code duplication analyze via flay'
task :flay do
  output = %x(bundle exec flay --mass 35 app/ lib/gitlab/)

  if output.include? "Similar code found"
    puts output
    exit 1
  end
end
