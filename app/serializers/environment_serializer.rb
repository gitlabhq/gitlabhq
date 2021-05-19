# frozen_string_literal: true

class EnvironmentSerializer < BaseSerializer
  include WithPagination

  Item = Struct.new(:name, :size, :latest)

  entity EnvironmentEntity

  def within_folders
    tap { @itemize = true }
  end

  def itemized?
    @itemize
  end

  def represent(resource, opts = {})
    if itemized?
      itemize(resource).map do |item|
        { name: item.name,
          size: item.size,
          latest: super(item.latest, opts) }
      end
    else
      resource = @paginator.paginate(resource) if paginated?

      super(batch_load(resource), opts)
    end
  end

  private

  # rubocop: disable CodeReuse/ActiveRecord
  def itemize(resource)
    items = resource.order('folder ASC')
      .group('COALESCE(environment_type, name)')
      .select('COALESCE(environment_type, name) AS folder',
              'COUNT(*) AS size', 'MAX(id) AS last_id')

    # It makes a difference when you call `paginate` method, because
    # although `page` is effective at the end, it calls counting methods
    # immediately.
    items = @paginator.paginate(items) if paginated?

    environments = batch_load(resource.where(id: items.map(&:last_id)))
    environments_by_id = environments.index_by(&:id)

    items.map do |item|
      Item.new(item.folder, item.size, environments_by_id[item.last_id])
    end
  end

  def batch_load(resource)
    resource = resource.preload(environment_associations)

    resource.all.to_a.tap do |environments|
      environments.each do |environment|
        # Batch loading the commits of the deployments
        environment.last_deployment&.commit&.try(:lazy_author)
        environment.upcoming_deployment&.commit&.try(:lazy_author)
      end
    end
  end

  def environment_associations
    {
      last_deployment: deployment_associations,
      upcoming_deployment: deployment_associations,
      project: project_associations
    }
  end

  def deployment_associations
    {
      user: [],
      cluster: [],
      project: [],
      deployable: {
        user: [],
        metadata: [],
        pipeline: {
          manual_actions: [],
          scheduled_actions: []
        },
        project: project_associations
      }
    }
  end

  def project_associations
    {
      project_feature: [],
      route: [],
      namespace: :route
    }
  end
  # rubocop: enable CodeReuse/ActiveRecord
end

EnvironmentSerializer.prepend_mod_with('EnvironmentSerializer')
