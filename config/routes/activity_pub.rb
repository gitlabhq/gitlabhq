# frozen_string_literal: true

constraints(::Constraints::ActivityPubConstrainer.new) do
  scope(module: 'activity_pub') do
    constraints(::Constraints::ProjectUrlConstrainer.new) do
      # Emulating route structure from routes/project.rb since we want to serve
      # ActivityPub content with the proper "Accept" header to the same urls. See
      # project routes file for rational behind this structure.
      scope(
        path: '*namespace_id',
        as: :namespace,
        namespace_id: Gitlab::PathRegex.full_namespace_route_regex
      ) do
        scope(
          path: ':project_id',
          constraints: { project_id: Gitlab::PathRegex.project_route_regex },
          module: :projects,
          as: :project
        ) do
          scope '-' do
            resources :releases, only: :index do
              collection do
                get 'outbox'
                post 'inbox'
              end
            end
          end
        end
      end
    end
  end
end
