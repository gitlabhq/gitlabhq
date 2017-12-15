get 'help'                        => 'help#index'
get 'help/shortcuts'              => 'help#shortcuts'
get 'help/ui'                     => 'help#ui'
get 'help/instance_configuration' => 'help#instance_configuration'
get 'help/*path'                  => 'help#show', as: :help_page

get 'manifest.json', to: 'manifest_json#index', as: :manifest_json
