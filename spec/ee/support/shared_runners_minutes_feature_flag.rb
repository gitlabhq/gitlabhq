RSpec.configure do |config|
  config.before(:all) do
    puts "this feature is by default disabled"
    Feature.get(:shared_runner_minutes_on_subnamespace).disable
  end
end
