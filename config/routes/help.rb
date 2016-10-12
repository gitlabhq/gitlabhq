get 'help'           => 'help#index'
get 'help/shortcuts' => 'help#shortcuts'
get 'help/ui'        => 'help#ui'
get 'help/*path'     => 'help#show', as: :help_page
