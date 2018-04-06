module EpicsHelper
  def epic_show_app_data(epic, opts)
    author = epic.author
    group = epic.group

    epic_meta = {
      created: epic.created_at,
      author: {
        name: author.name,
        url: user_path(author),
        username: "@#{author.username}",
        src: opts[:author_icon]
      },
      start_date: epic.start_date,
      end_date: epic.end_date
    }

    {
      initial: opts[:initial].merge(labels: epic.labels).to_json,
      meta: epic_meta.to_json,
      namespace: group.path,
      labels_path: group_labels_path(group, format: :json, only_group_labels: true, include_ancestor_groups: true),
      labels_web_url: group_labels_path(group),
      epics_web_url: group_epics_path(group)
    }
  end

  def epic_endpoint_query_params(opts)
    opts[:data] ||= {}
    opts[:data][:endpoint_query_params] = {
        only_group_labels: true,
        include_ancestor_groups: true,
        include_descendant_groups: true
    }.to_json

    opts
  end
end
