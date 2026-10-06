# frozen_string_literal: true

namespace :gems do
  desc 'Gems | Print the dependency graph between the monolith and the in-repo gems ' \
    'as JSON (default) or Mermaid, e.g. gems:dependency_graph[mermaid]'
  task :dependency_graph, [:format] do |_task, args|
    require 'json'
    require_relative '../../../tooling/lib/tooling/dependency_graph/graph'

    root = File.expand_path('../../..', __dir__)
    graph = Tooling::DependencyGraph::Graph.new(root: root)

    case args.fetch(:format, 'json')
    when 'json' then puts JSON.pretty_generate(graph.to_h) # rubocop:disable Gitlab/Json -- must run without Rails
    when 'mermaid' then puts graph.to_mermaid
    else abort "Unknown format '#{args[:format]}'. Use 'json' or 'mermaid'."
    end
  end
end
