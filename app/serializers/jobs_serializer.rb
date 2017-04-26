class JobsSerializer < BaseSerializer
  Item = Struct.new(:name, :size, :list)

  entity BuildEntity

  def with_groups
    tap { @groups = true }
  end

  def groups?
    @groups
  end

  def represent(resource, opts = {})
    if groups?
      groups(resource).map do |item|
        { name: item.name,
          size: item.size,
          list: super(item.list, opts),
          status: represent_status(item.status) }
      end
    else
      super(resource, opts)
    end
  end

  private

  def represent_status(list, opts = {})
    # TODO: We don't really have a first class concept
    # for JobsGroup that would make it possible to have status for that
    detailed_status =
      if group_jobs.one?
        group_jobs.first.detailed_status(request.user)
      else
        Gitlab::Ci::Status::Group::Factory
            .new(CommitStatus.where(id: group_jobs), request.user)
            .fabricate!
      end

    StatusEntity
      .represent(resource, opts.merge(request: @request))
      .as_json
  end

  def groups(resource)
    items = resource.sort_by(&:sortable_name).group_by(&:group_name)

    items.map do |group_name, group_jobs|
      Item.new(group_name, group_jobs.size, group_jobs)
    end
  end
end
