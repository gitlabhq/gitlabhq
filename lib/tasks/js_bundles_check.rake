require 'json'

desc 'GitLab | Check JavaScript bundle files for suboptimal bundling'
task :js_bundles_check do
  bundle_stats_file = File.read('./webpack-report/stats.json')
  bundle_stats = JSON.parse(bundle_stats_file)

  vue_module = bundle_stats['modules'].find { |bundle_module| bundle_module['identifier'].end_with?('vue.esm.js') }
  main_bundle = bundle_stats['chunks'].find { |chunk| chunk['names'].include?('main') }

  abort('vue.esm.js found within main.js') if vue_module['chunks'].include?(main_bundle['id'])
end
