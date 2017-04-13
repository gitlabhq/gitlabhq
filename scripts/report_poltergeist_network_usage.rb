require './spec/support/poltergeist_network_monitor'

stores = Dir.glob('tmp/capybara/network_requests_*.pstore')
requests = stores.flat_map do |path|
  PoltergeistNetworkMonitor::DataStore.new(path).load_requests
end

File.open('tmp/capybara/network_request_stats.txt', 'w') do |file|
  PoltergeistNetworkMonitor::Stats.new(requests).print_summary(file)
end

merged_path = 'tmp/capybara/all_network_requests.pstore'
PoltergeistNetworkMonitor::DataStore.new(merged_path).store_requests(requests)
