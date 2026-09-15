# frozen_string_literal: true

module Gitlab
  # Resolves a project or a group from either a numeric ID or a full path.
  # Callers keep their own authorization and their own not-found handling, because the REST API
  # answers with Grape throws while other callers raise or return nil.
  module ResourceLookup
    INTEGER_ID_REGEX = /^-?\d+$/

    private

    # rubocop: disable CodeReuse/ActiveRecord -- no need to redefine a scope for the built-in method
    def lookup_project(id, scope: ::Project.without_deleted.not_hidden)
      return unless id

      if INTEGER_ID_REGEX.match?(id.to_s)
        scope.find_by(id: id)
      elsif id.to_s.include?('/')
        scope.find_by_full_path(id, follow_redirects: true)
      end
    end

    def lookup_group(id, scope: ::Group.all)
      if INTEGER_ID_REGEX.match?(id.to_s)
        scope.find_by(id: id)
      else
        scope.find_by_full_path(id)
      end
    end

    # Numeric IDs go in one query; paths keep the single lookup, because
    # find_by_full_path follows renames and a single WHERE cannot reproduce that.
    #
    # So a list of paths still costs a query each. That is bounded today because the only
    # unbounded arguments -- attach_scan_profile's project_ids and group_ids -- are
    # declared as Global IDs. A list argument accepting paths would reintroduce the
    # fan-out and should batch them through Route instead.
    def lookup_projects(ids, scope: ::Project.without_deleted.not_hidden)
      numeric, paths = partition_identifiers(ids)
      found = numeric.present? ? scope.id_in(numeric).to_a : []

      found + paths.filter_map { |path| lookup_project(path, scope: scope) }
    end

    def lookup_groups(ids, scope: ::Group.all)
      numeric, paths = partition_identifiers(ids)
      found = numeric.present? ? scope.id_in(numeric).to_a : []

      found + paths.filter_map { |path| lookup_group(path, scope: scope) }
    end

    def partition_identifiers(ids)
      Array(ids).compact.partition { |id| INTEGER_ID_REGEX.match?(id.to_s) }
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
