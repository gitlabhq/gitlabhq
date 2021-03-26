# frozen_string_literal: true

scope '-' do
  namespace :customers_dot do
    post 'proxy/graphql' => 'proxy#graphql'
  end
end
