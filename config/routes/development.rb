# frozen_string_literal: true

if Rails.env.development?
  # Make the built-in Rails routes available in development, otherwise they'd
  # get swallowed by the `namespace/project` route matcher below.
  #
  # See https://git.io/va79N
  get '/rails/mailers'         => 'rails/mailers#index'
  get '/rails/mailers/:path'   => 'rails/mailers#preview'
  get '/rails/info/properties' => 'rails/info#properties'
  get '/rails/info/routes'     => 'rails/info#routes'
  get '/rails/info'            => 'rails/info#index'

  mount LetterOpenerWeb::Engine, at: '/rails/letter_opener'
  mount Lookbook::Engine, at: '/rails/lookbook'
  mount Toogle::Engine, at: '/rails/features'
end
