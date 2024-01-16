# frozen_string_literal: true

module Routes
  class RenameDescendantsService
    BATCH_SIZE = 100
    class RouteChanges
      attr_reader :saved_change_to_parent_path, :saved_change_to_parent_name, :old_path_of_parent, :old_name_of_parent

      def initialize(changes)
        path_details = changes.fetch(:path)
        name_details = changes.fetch(:name)

        @saved_change_to_parent_path = path_details.fetch(:saved)
        @old_path_of_parent = path_details.fetch(:old_value)
        @saved_change_to_parent_name = name_details.fetch(:saved)
        @old_name_of_parent = name_details.fetch(:old_value)
      end
    end

    def initialize(parent_route)
      @parent_route = parent_route
      @routes_to_update = []
      @redirect_routes_to_insert = []
    end

    def execute(changes)
      process_changes(changes)
      update_routes_for_descendants
      create_redirect_routes_for_descendants
    end

    private

    def process_changes(changes)
      changes = RouteChanges.new(changes)

      saved_change_to_parent_path = changes.saved_change_to_parent_path
      saved_change_to_parent_name = changes.saved_change_to_parent_name

      return unless saved_change_to_parent_path || saved_change_to_parent_name

      old_path_of_parent = changes.old_path_of_parent
      old_name_of_parent = changes.old_name_of_parent

      descendant_routes_inside(old_path_of_parent).each_batch(of: BATCH_SIZE) do |relation|
        relation.each do |descendant_route|
          attributes_to_update = {}

          if saved_change_to_parent_path && descendant_route.path.present?
            attributes_to_update[:path] = descendant_route.path.sub(
              old_path_of_parent, current_path_of_parent
            )
          end

          if saved_change_to_parent_name && old_name_of_parent.present? && descendant_route.name.present?
            attributes_to_update[:name] = descendant_route.name.sub(
              old_name_of_parent, current_name_of_parent
            )
          end

          push_to_routes_data(descendant_route, attributes_to_update)
          push_to_redirect_routes_data(descendant_route) if attributes_to_update[:path]
        end
      end
    end

    def push_to_routes_data(descendant_route, attributes_to_update)
      return if attributes_to_update.empty?

      # We merge updated attributes with all existing attributes of the `Route` record.
      # This comprehensive attribute set is required for the initial attempt of `upsert_all` to function effectively.
      # During the first phase (insertion attempt), `upsert_all` tries to insert new records into the database,
      # necessitating the presence of all attributes, including NOT NULL attributes, to create new entries.
      # Attributes like `source_id` and `source_type` are crucial, as they are NOT NULL attributes essential
      # for record creation.
      # In the event of conflicts (e.g., existing Route records with conflicting `id`s),
      # `upsert_all` switches to an update operation for those specific conflicted records.
      # And this is the way we get to update `path` and/or `name` of multiple, existing route records in one go.
      @routes_to_update << descendant_route
        .attributes.symbolize_keys
        .merge(attributes_to_update)
    end

    def push_to_redirect_routes_data(descendant_route)
      @redirect_routes_to_insert << {
        source_id: descendant_route.source_id,
        source_type: descendant_route.source_type,
        path: descendant_route.path
      }
    end

    def update_routes_for_descendants
      return if @routes_to_update.blank?

      @routes_to_update.each_slice(BATCH_SIZE) do |data|
        # Utilizing `upsert_all` with `unique_by: :id` ensures that only updates occur,
        # as the provided data contains attributes exclusively for existing `Route` records,
        # identified by their unique `id`.
        # This upsert operation is hence guaranteed to solely execute updates, never inserts.
        Route.upsert_all(
          data,
          unique_by: :id,
          update_only: [:path, :name], # on conflicts, we need to update only path/name.
          record_timestamps: true # this makes sure that `updated_at` is updated.
        )
      end
    end

    def create_redirect_routes_for_descendants
      return if @redirect_routes_to_insert.blank?

      @redirect_routes_to_insert.each_slice(BATCH_SIZE) do |data|
        RedirectRoute.insert_all(
          data,
          # We need to make sure no duplicates are inserted.
          # We use the value of `lower(path)` to make this check,
          # which is already a UNIQUE index on this table.
          unique_by: :index_redirect_routes_on_path_unique_text_pattern_ops
        )
      end
    end

    def current_name_of_parent
      @parent_route.name
    end

    def current_path_of_parent
      @parent_route.path
    end

    def descendant_routes_inside(path)
      Route.inside_path(path)
    end
  end
end
