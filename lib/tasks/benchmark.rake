# frozen_string_literal: true

return if Rails.env.production?

namespace :benchmark do
  desc 'Benchmark | Banzai pipeline/filters'
  RSpec::Core::RakeTask.new(:banzai) do |t|
    t.pattern = 'spec/benchmarks/banzai_benchmark.rb'
    ENV['BENCHMARK'] = '1'
  end
end
