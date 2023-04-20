# frozen_string_literal: true

scope(
  path: '*namespace_id',
  as: :namespace,
  namespace_id: Gitlab::PathRegex.full_namespace_route_regex
) do
  scope(
    path: ':project_id',
    constraints: { project_id: Gitlab::PathRegex.project_route_regex },
    as: :project
  ) do
    post '*all', to: 'application#route_not_found'
    put '*all', to: 'application#route_not_found'
    patch '*all', to: 'application#route_not_found'
    delete '*all', to: 'application#route_not_found'
    post '/', to: 'application#route_not_found'
    put '/', to: 'application#route_not_found'
    patch '/', to: 'application#route_not_found'
    delete '/', to: 'application#route_not_found'
  end
end
