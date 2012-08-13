namespace :dev do
  desc "DEV | Run cucumber and rspec"
  task :tests do
    ["cucumber", "rspec spec"].each do |cmd|
      puts "Starting to run #{cmd}..."
      system("bundle exec #{cmd}")
      raise "#{cmd} failed!" unless $?.exitstatus == 0
    end
  end
end
