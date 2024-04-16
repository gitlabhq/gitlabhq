# frozen_string_literal: true

get 'help'                        => 'help#index'
get 'help/shortcuts'              => 'help#shortcuts'
get 'help/instance_configuration' => 'help#instance_configuration'
get 'help/drawers/*markdown_file' => 'help#drawers'
get 'help/docs'                   => 'help#redirect_to_docs'
get 'help/*path'                  => 'help#show', as: :help_page
