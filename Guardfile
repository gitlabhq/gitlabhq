# frozen_string_literal: true

# More info at https://github.com/guard/guard#readme

require "guard/rspec/dsl"

cmd = ENV['GUARD_CMD'] || (ENV['SPRING'] ? 'spring rspec' : 'bundle exec rspec')

directories %w[app ee keeps lib rubocop scripts spec tooling]

rspec_context_for = proc do |context_path|
  OpenStruct.new(to_s: "spec").tap do |rspec| # rubocop:disable Style/OpenStructUse
    rspec.spec_dir = "#{context_path}spec"
    rspec.spec = ->(m) { Guard::RSpec::Dsl.detect_spec_file_for(rspec, m) }
    rspec.spec_helper = "#{rspec.spec_dir}/spec_helper.rb"
    rspec.spec_files = %r{^#{rspec.spec_dir}/.+_spec\.rb$}
    rspec.spec_support = %r{^#{rspec.spec_dir}/support/(.+)\.rb$}
  end
end

rails_context_for = proc do |context_path, exts|
  OpenStruct.new.tap do |rails| # rubocop:disable Style/OpenStructUse
    rails.app_files = %r{^#{context_path}app/(.+)\.rb$}

    rails.views = %r{^#{context_path}app/(views/.+/[^/]*\.(?:#{exts}))$}
    rails.view_dirs = %r{^#{context_path}app/views/(.+)/[^/]*\.(?:#{exts})$}
    rails.layouts = %r{^#{context_path}app/layouts/(.+)/[^/]*\.(?:#{exts})$}

    rails.controllers = %r{^#{context_path}app/controllers/(.+)_controller\.rb$}
    rails.routes = "#{context_path}config/routes.rb"
    rails.app_controller = "#{context_path}app/controllers/application_controller.rb"
    rails.spec_helper = "#{context_path}spec/rails_helper.rb"
  end
end

guard_setup = proc do |context_path|
  # RSpec files
  rspec = rspec_context_for.call(context_path)
  watch(rspec.spec_helper) { rspec.spec_dir }
  watch(rspec.spec_support) { rspec.spec_dir }
  watch(rspec.spec_files)

  # Ruby files
  watch(%r{^#{context_path}(keeps/.+)\.rb$}) { |m| rspec.spec.call(m[1]) }
  watch(%r{^#{context_path}(lib/.+)\.rb$}) { |m| rspec.spec.call(m[1]) }
  watch(%r{^#{context_path}(rubocop/.+)\.rb$}) { |m| rspec.spec.call(m[1]) }
  watch(%r{^#{context_path}(tooling/.+)\.rb$}) { |m| rspec.spec.call(m[1]) }
  watch(%r{^#{context_path}(scripts/.+)\.rb$}) { |m| rspec.spec.call(m[1].tr('-', '_')) }

  # Rails files
  rails = rails_context_for.call(context_path, %w[erb haml slim])
  watch(rails.app_files) { |m| rspec.spec.call(m[1]) }
  watch(rails.views)     { |m| rspec.spec.call(m[1]) }

  watch(rails.controllers) do |m|
    [
      rspec.spec.call("routing/#{m[1]}_routing"),
      rspec.spec.call("controllers/#{m[1]}_controller")
    ]
  end

  # Rails config changes
  watch(rails.spec_helper)     { rspec.spec_dir }
  watch(rails.routes)          { "#{rspec.spec_dir}/routing" }
  watch(rails.app_controller)  { "#{rspec.spec_dir}/controllers" }

  # Capybara features specs
  watch(rails.view_dirs)     { |m| rspec.spec.call("features/#{m[1]}") }
  watch(rails.layouts)       { |m| rspec.spec.call("features/#{m[1]}") }
end

context_paths = ['', 'ee/']

context_paths.each do |context_path|
  guard :rspec, cmd: cmd, spec_paths: ["#{context_path}spec/"] do
    guard_setup.call(context_path)
  end
end
