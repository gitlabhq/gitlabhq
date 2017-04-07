require './spec/simplecov_env'
SimpleCovEnv.start!

ENV['RAILS_ENV'] = 'test'
require './config/environment'
require 'rspec/expectations'

if ENV['CI']
  require 'knapsack'
  Knapsack::Adapters::SpinachAdapter.bind
end

%w(select2_helper test_env repo_helpers wait_for_ajax sidekiq).each do |f|
  require Rails.root.join('spec', 'support', f)
end

Dir["#{Rails.root}/features/steps/shared/*.rb"].each { |file| require file }

WebMock.allow_net_connect!

Spinach.hooks.before_run do
  include RSpec::Mocks::ExampleMethods
  RSpec::Mocks.setup
  TestEnv.init(mailer: false)

  # skip pre-receive hook check so we can use
  # web editor and merge
  TestEnv.disable_pre_receive

  include FactoryGirl::Syntax::Methods
end

module StdoutReporterWithScenarioLocation
  # Override the standard reporter to show filename and line number next to each
  # scenario for easy, focused re-runs
  def before_scenario_run(scenario, step_definitions = nil)
    @max_step_name_length = scenario.steps.map(&:name).map(&:length).max if scenario.steps.any?
    name = scenario.name

    # This number has no significance, it's just to line things up
    max_length = @max_step_name_length + 19
    out.puts "\n  #{'Scenario:'.green} #{name.light_green.ljust(max_length)}" \
      " # #{scenario.feature.filename}:#{scenario.line}"
  end
end

Spinach::Reporter::Stdout.prepend(StdoutReporterWithScenarioLocation)
