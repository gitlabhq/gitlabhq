require 'json'

desc 'GitLab | Check JavaScript bundle files for suboptimal bundling'
task :js_bundles_check do
  js_bundle_checker = JsBundleChecker.new('./webpack-report/stats.json')

  causal_factor_tree, target_node = js_bundle_checker.check_chunk_for('main', './app/assets/javascripts/main.js', './~/vue/dist/vue.esm.js')

  next if causal_factor_tree.nil?

  abort("\n\nvue.esm.js module found within main.js bundle.\n\n#{target_node[:dependency_text]}\n\n")
end

class JsBundleChecker
  def initialize(stats_file)
    @stats_file = stats_file
  end

  def check_chunk_for(chunk_name, bundle_name, module_name)
    parse_bundle_stats

    chunk = find_chunk(chunk_name)
    the_module = find_module(module_name)

    return [nil, nil] unless is_module_in_chunk?(chunk, the_module)

    build_causal_factor_tree(the_module, bundle_name)
  end

  def is_module_in_chunk?(chunk, the_module)
    the_module['chunks'].include?(chunk['id'])
  end

  private

  def parse_bundle_stats
    bundle_stats_file = File.read(@stats_file)

    @bundle_stats = JSON.parse(bundle_stats_file)
  end

  def find_module(module_name)
    @bundle_stats['modules'].find { |bundle_module| bundle_module['name'] == module_name }
  end

  def find_chunk(chunk_name)
    @bundle_stats['chunks'].find { |chunk| chunk['names'].include?(chunk_name) }
  end

  def build_causal_factor_tree(root_module, target_bundle_name)
    root = create_node(root_module)

    build_parent_nodes(root, target_bundle_name)
  end

  def build_parent_nodes(current_node, target_bundle_name, target_node = nil)
    current_node[:module]['reasons'].each do |parent|
      parent_module = find_module(parent['moduleName'])

      parent_node = create_node(parent_module, current_node)

      target_node = parent_node if parent_node[:name] == target_bundle_name

      parent_node, target_node = build_parent_nodes(parent_node, target_bundle_name, target_node)

      current_node[:parents] = current_node[:parents].push(parent_node)
    end

    [current_node, target_node]
  end

  def create_node(the_module, child_module = nil)
    {
      name: the_module['name'],
      module: the_module,
      parents: [],
      dependency_text: get_dependency_text(the_module, child_module)
    }
  end

  def get_dependency_text(parent_module, child_module)
    return parent_module['name'] if child_module.nil?

    "#{parent_module['name']}\n            ↑\n#{child_module[:dependency_text]}"
  end
end
