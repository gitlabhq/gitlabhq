#!/usr/bin/env ruby
# frozen_string_literal: true

require "rubocop"

# Shows ABC size of methods and blocks for passed files.
#
# See https://docs.rubocop.org/rubocop/cops_metrics.html#metricsabcsize
#
# Usage: scripts/ruby-metrics-abc.rb <ruby file> ...
#   Example: scripts/ruby-metrics-abc.rb app/models/project.rb app/models/user.rb

module Tooling
  class MetricsABC
    extend RuboCop::AST::NodePattern::Macros
    include RuboCop::AST::Traversal

    def run(source)
      version = RUBY_VERSION[/^(\d+\.\d+)/, 1].to_f
      ast = RuboCop::AST::ProcessedSource.new(source, version).ast

      walk(ast)
    end

    def on_def(node)
      print_abc("def #{node.method_name}", node)
    end

    def on_defs(node)
      print_abc("def self.#{node.method_name}", node)
    end

    def on_block(node)
      return unless node.parent&.send_type?

      method_name = node.parent.method_name
      arguments = node.parent.arguments.select { |n| n.sym_type? || n.str_type? }.map(&:source)

      print_abc("#{method_name}(#{arguments.join(', ')})", node)
    end

    private

    def print_abc(prefix, node)
      # https://www.rubydoc.info/gems/rubocop/RuboCop/Cop/Metrics/Utils/AbcSizeCalculator#calculate-instance_method
      abc_score, abc_vector = RuboCop::Cop::Metrics::Utils::AbcSizeCalculator
        .calculate(node, discount_repeated_attributes: true) # rubocop:disable CodeReuse/ActiveRecord -- This is not AR
      puts format("  %d: %s: %.2f %s", node.first_line, prefix, abc_score, abc_vector)
    end
  end

  if ARGV.empty?
    puts "Usage: scripts/ruby-metrics-abc.rb <ruby file> ..."
    puts "  Example: scripts/ruby-metrics-abc.rb app/models/project.rb app/models/user.rb"
  end

  ARGV.each do |file|
    puts "Checking #{file}:"

    MetricsABC.new.run(File.read(file))
  end
end
