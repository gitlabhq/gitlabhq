require_relative '../../app/services/git_gc.rb'

task :git_gc  => :environment do
  GitGc.new.cleanup
  exit 0
end
