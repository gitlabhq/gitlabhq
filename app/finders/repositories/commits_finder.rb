# frozen_string_literal: true

module Repositories
  class CommitsFinder
    # Raised when keyset pagination is requested together with a parameter the
    # Gitaly keyset path cannot honor. Subclasses ArgumentError so callers that
    # rescue ArgumentError keep working, while the API endpoint can rescue this
    # specific class to route the error without inspecting the message string.
    UnsupportedKeysetParamError = Class.new(ArgumentError)

    attr_reader :next_cursor

    UNSUPPORTED_KEYSET_PARAMS = %w[first_parent order trailers follow].freeze
    # Message fragment used to build the user-facing error. It omits the verb
    # ("is"/"are") so it reads correctly in both the singular and plural forms.
    KEYSET_PARAM_ERROR_SUFFIX = 'not supported with keyset pagination'

    def initialize(project, params = {})
      @project = project
      @params = params
      @next_cursor = nil
    end

    def execute(gitaly_pagination: false)
      return [] unless project.repository_exists?

      if gitaly_pagination
        execute_with_gitaly_pagination
      else
        execute_with_offset_pagination
      end
    end

    private

    attr_reader :project, :params

    def execute_with_gitaly_pagination
      validate_keyset_params!

      response = project.repository.list_commits(
        ref: effective_ref,
        author: params[:author],
        path: sanitized_path.presence,
        literal_pathspec: sanitized_path.present?,
        committed_before: params[:until],
        committed_after: params[:since],
        pagination_params: pagination_params
      )

      @next_cursor = response.next_cursor
      response
    end

    def execute_with_offset_pagination
      project.repository.commits(
        offset_ref,
        path: sanitized_path,
        limit: limit,
        offset: offset,
        before: params[:until],
        after: params[:since],
        all: !!params[:all],
        first_parent: !!params[:first_parent],
        order: params[:order],
        author: params[:author],
        trailers: params[:trailers],
        follow: params[:follow]
      )
    end

    def effective_ref
      params[:all] ? '--all' : (params[:ref_name].presence || project.default_branch)
    end

    def offset_ref
      params[:ref_name].presence || project.default_branch unless params[:all]
    end

    def sanitized_path
      params[:path].to_s.sub(%r{^/+}, '')
    end

    def validate_keyset_params!
      unsupported = UNSUPPORTED_KEYSET_PARAMS.select { |p| param_present?(p) }
      return if unsupported.empty?

      raise UnsupportedKeysetParamError, unsupported_keyset_params_error(unsupported)
    end

    def unsupported_keyset_params_error(unsupported_params)
      names = unsupported_params.map { |p| "'#{p}'" }.join(', ')
      pluralized = unsupported_params.one? ? 'parameter is' : 'parameters are'

      "The #{names} #{pluralized} #{KEYSET_PARAM_ERROR_SUFFIX}"
    end

    def param_present?(name)
      return order_present? if name == 'order'

      value = params[name.to_sym]

      return false if value.nil?
      return false if value == false
      return false if value.to_s.empty?

      true
    end

    def order_present?
      params[:order].present? && params[:order].to_s != 'default'
    end

    def pagination_params
      { limit: limit, page_token: params[:page_token] }
    end

    def limit
      per_page = params[:per_page].to_i
      per_page = Kaminari.config.default_per_page if per_page <= 0
      [per_page, Kaminari.config.max_per_page].min
    end

    def offset
      page = params[:page].to_i
      page = 1 if page <= 0
      (page - 1) * limit
    end
  end
end
