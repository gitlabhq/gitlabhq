# frozen_string_literal: true

return if Rails.env.production?

namespace :benchmark do
  desc 'Benchmark | Banzai pipeline/filters (optionally specify FILTER=xxxxxFilter)'
  RSpec::Core::RakeTask.new(:banzai) do |t|
    t.pattern = 'spec/benchmarks/banzai_benchmark.rb'
    t.rspec_opts = if ENV.key?('FILTER')
                     ['--tag specific_filter']
                   else
                     ['--tag \~specific_filter']
                   end

    ENV['BENCHMARK'] = '1'
  end
end
