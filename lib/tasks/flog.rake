desc 'Code complexity analyze via flog'
task :flog do
  output = %x(bundle exec flog -m app/ lib/gitlab)
  exit_code = 0
  minimum_score = 70
  output = output.lines

  # Skip total complexity score
  output.shift

  # Skip some trash info
  output.shift

  output.each do |line|
    score, method = line.split(" ")
    score = score.to_i

    if score > minimum_score
      exit_code = 1
      puts "High complexity in #{method}. Score: #{score}"
    end
  end

  exit exit_code
end
