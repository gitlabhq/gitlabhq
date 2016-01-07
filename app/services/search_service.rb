class SearchService < BaseService
  def global_search
    query = params[:search]

    {
        groups: search_in_groups(query),
        users: search_in_users(query),
        projects: search_in_projects(query),
        merge_requests: search_in_merge_requests(query),
        issues: search_in_issues(query)
    }
  end

  def project_search(project)
    query = params[:search]

    {
        groups: {},
        users: {},
        projects: {},
        merge_requests: search_in_merge_requests(query, project),
        issues: search_in_issues(query, project)
    }
  end

  private

  def search_in_projects(query)
    opt = {
      pids: projects_ids,
      order: params[:order],
      fields: %w(name^10 path^9 description^5
             name_with_namespace^2 path_with_namespace),
      highlight: true
    }

    group = Group.find_by(id: params[:group_id]) if params[:group_id].present?

    opt[:namespace_id] = group.id if group

    opt[:category] = params[:category] if params[:category].present?

    begin
      response = Project.elastic_search(query, options: opt, page: page)

      categories_list = if query.blank?
                          Project.category_counts.map do |category|
                            { category: category.name, count: category.count }
                          end
                        else
                          response.response["facets"]["categoryFacet"]["terms"].map do |term|
                            { category: term["term"], count: term["count"] }
                          end
                        end

      {
        records: response.records,
        results: response.results,
        response: response.response,
        total_count: response.total_count,
        namespaces: namespaces(response.response["facets"]["namespaceFacet"]["terms"]),
        categories: categories_list
      }
    rescue Exception => e
      {}
    end
  end

  def search_in_groups(query)
    opt = {
      gids: current_user ? current_user.authorized_groups.ids : [],
      order: params[:order],
      fields: %w(name^10 path^5 description),
      highlight: true
    }

    begin
      response = Group.elastic_search(query, options: opt, page: page)

      {
        records: response.records,
        results: response.results,
        response: response.response,
        total_count: response.total_count
      }
    rescue Exception => e
      {}
    end
  end

  def search_in_users(query)
    opt = {
      active: true,
      order: params[:order],
      highlight: true
    }

    begin
      response = User.elastic_search(query, options: opt, page: page)

      {
        records: response.records,
        results: response.results,
        response: response.response,
        total_count: response.total_count
      }
    rescue Exception => e
      {}
    end
  end

  def search_in_merge_requests(query, project = nil)
    opt = {
      projects_ids: project ? [project.id] : projects_ids,
      order: params[:order],
      highlight: true
    }

    begin
      response = MergeRequest.elastic_search(query, options: opt, page: page)

      {
        records: response.records,
        results: response.results,
        response: response.response,
        total_count: response.total_count
      }
    rescue Exception => e
      {}
    end
  end

  def search_in_issues(query, project = nil)
    opt = {
      projects_ids: project ? [project.id] : projects_ids,
      order: params[:order]
    }

    begin
      response = Issue.elastic_search(query, options: opt, page: page)

      {
        records: response.records,
        results: response.results,
        response: response.response,
        total_count: response.total_count
      }
    rescue Exception => e
      {}
    end
  end

  def projects_ids
    @allowed_projects_ids ||= begin
      if params[:namespace].present?
        namespace = Namespace.find_by(path: params[:namespace])

        if namespace
          return namespace.projects.where(id: known_projects_ids).pluck(:id)
        end
      end

      known_projects_ids
    end
  end

  def page
    return @current_page if defined?(@current_page)

    @current_page = params[:page].to_i
    @current_page = 1 if @current_page == 0
    @current_page
  end

  def known_projects_ids
    known_projects_ids = []
    known_projects_ids += current_user.authorized_projects.pluck(:id) if current_user
    known_projects_ids + Project.public_and_internal_only.pluck(:id)
  end

  def project_filter(es_results)
    terms = es_results.
        select { |term| term['count'] > 0 }.
        inject({}) do |memo, term|
          memo[term["term"]] = term["count"]
          memo
        end

    projects_meta_data = Project.joins(:namespace).where(id: terms.keys).
        pluck(['projects.name','projects.path',
               'namespaces.name as namespace_name',
               'namespaces.path as namespace_path',
               'projects.id'].join(","))

    if projects_meta_data.any?
      projects_meta_data.map do |meta|
        {
          name: meta[2] + ' / ' + meta[0],
          path: meta[3] + ' / ' + meta[1],
          count: terms[meta[4]]
        }
      end.sort { |x, y| y[:count] <=> x[:count] }
    else
      []
    end
  end

  def namespaces(terms)
    founded_terms = terms.select { |term| term['count'] > 0 }
    grouped_terms = founded_terms.inject({}) do |memo, term|
      memo[term["term"]] = term["count"]
      memo
    end

    namespaces_meta_data = Namespace.find(grouped_terms.keys)

    if namespaces_meta_data.any?
      namespaces_meta_data.map do |namespace|
        { namespace: namespace, count: grouped_terms[namespace.id] }
      end.sort { |x, y| y[:count] <=> x[:count] }
    else
      []
    end
  end
end
