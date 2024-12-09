# frozen_string_literal: true

if $LOADED_FEATURES.include?(File.expand_path('spec_helper.rb', __dir__))
  # There's no need to load anything here if spec_helper is already loaded
  # because spec_helper is more extensive than fast_spec_helper
  return
end

require_relative '../config/bundler_setup'
require 'benchmark'

module FastSpecHelper
  def self.slower_app_requires
    require 'active_support/all'
    require 'pry'
  end

  def self.app_requires
    require_relative 'deprecation_warnings'
    require 'gitlab/utils/all'
    require_relative 'rails_autoload'
    ENV['IN_MEMORY_APPLICATION_SETTINGS'] = 'true'
    require_relative '../config/settings'
    require_relative '../lib/gitlab'
  end

  def self.slower_spec_requires
    require 'rspec-parameterized'
    require_relative 'support/rspec'
  end

  def self.spec_requires_and_configuration
    require 'gitlab/rspec/next_instance_of'
    require_relative 'support/matchers/result_matchers'
    require_relative 'support/railway_oriented_programming'
    require_relative 'simplecov_env'

    # NOTE: Consider making any common RSpec configuration tweaks in `spec/support/rspec.rb` instead of here,
    # because it is also used by `spec/spec_helper.rb`.
    RSpec.configure do |config|
      config.include NextInstanceOf
      config.disable_monkey_patching! # Enable zero monkey patching mode before loading any other RSpec code.
      config.mock_with :rspec do |mocks|
        mocks.verify_doubled_constant_names = false # Allow mocking of non-lib module/class names from Rails
      end

      # Mock out the GettextI18nRails `_` method to just pass through the key as the text
      config.before do
        allow(described_class).to(receive(:_)) { |key| key }
      end
    end

    Time.zone = 'UTC' # rubocop:disable Gitlab/ChangeTimezone -- allow Time.zone to not be nil in fast_spec_helper, so Time.zone.now works
  end

  def self.domain_specific_spec_helper_support
    # If you want to extensively use `fast_spec_helper` for your domain or
    # bounded context (https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/modular_monolith/bounded_contexts/),
    # but don't want to have to repeat the same require statement or configuration across multiple spec files, you can
    # add a custom fast_spec_helper for your domain and require it here.
    # Just make sure your additions don't do anything to noticably increase the runtime of `fast_spec_helper`!

    # Remote Development domain
    require_relative('../ee/spec/support/fast_spec/remote_development/fast_spec_helper_support') if Gitlab.ee?

    # Web IDE domain
    require_relative 'support/fast_spec/web_ide/fast_spec_helper_support'
  end

  def self.post_require_configuration
    SimpleCovEnv.start!
    ActiveSupport::XmlMini.backend = 'Nokogiri'
  end

  def self.with_slow_execution_warning(max_allowed:)
    data = Benchmark.measure do
      yield
    end

    total = data.total

    return if total < max_allowed

    warn "\n\nWarning: fast_spec_helper submodule took longer than max allowed execution time " \
      "of #{max_allowed}: #{total}\n"
    warn "Slow submodule invoked from: #{caller[0]}\n\n"
  end

  def self.run
    # NOTE: These max_allowed times are generally 2-4 times higher than the actual average
    #       execution times, to avoid false warnings on slower machines or CI runners.
    with_slow_execution_warning(max_allowed: 2.0) { slower_app_requires }
    with_slow_execution_warning(max_allowed: 0.2) { app_requires }
    with_slow_execution_warning(max_allowed: 1.0) { slower_spec_requires }
    with_slow_execution_warning(max_allowed: 0.2) { spec_requires_and_configuration }
    with_slow_execution_warning(max_allowed: 1.0) { domain_specific_spec_helper_support }
    with_slow_execution_warning(max_allowed: 0.2) { post_require_configuration }
  end
end

FastSpecHelper.run

require_relative('../jh/spec/fast_spec_helper') if Gitlab.jh?
