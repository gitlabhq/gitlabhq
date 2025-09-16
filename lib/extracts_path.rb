# frozen_string_literal: true

# Module providing methods for dealing with separating a tree-ish string and a
# file path string when combined in a request parameter
# rubocop:disable Gitlab/ModuleWithInstanceVariables -- will be fixed in https://gitlab.com/gitlab-org/gitlab/-/issues/425379
module ExtractsPath
  InvalidPathError = ExtractsRef::RefExtractor::InvalidPathError
  BRANCH_REF_TYPE = ExtractsRef::RefExtractor::BRANCH_REF_TYPE
  TAG_REF_TYPE = ExtractsRef::RefExtractor::TAG_REF_TYPE
  REF_TYPES = ExtractsRef::RefExtractor::REF_TYPES

  # Extends the method to handle if there is no path and the ref doesn't
  # exist in the repo, try to resolve the ref without an '.atom' suffix.
  # If _that_ ref is found, set the request's format to Atom manually.
  #
  # Automatically renders `not_found!` if a valid tree path could not be
  # resolved (e.g., when a user inserts an invalid path or ref).
  #
  # Automatically redirects to the current default branch if the ref matches a
  # previous default branch that has subsequently been deleted.
  #
  # Assignments are:
  #
  # - @id     - A string representing the joined ref and path
  # - @ref    - A string representing the ref (e.g., the branch, tag, or commit SHA)
  # - @path   - A string representing the filesystem path
  # - @commit - A Commit representing the commit from the given ref
  #
  # If the :id parameter appears to be requesting a specific response format,
  # that will be handled as well.
  def assign_ref_vars
    ref_extractor = ExtractsRef::RefExtractor.new(repository_container, params.permit(:id, :ref, :path, :ref_type))
    ref_extractor.extract!

    @id = ref_extractor.id
    @ref = ref_extractor.ref
    @path = ref_extractor.path
    @repo = ref_extractor.repo

    if @ref.present?
      @commit = ref_extractor.commit
      @fully_qualified_ref = ref_extractor.fully_qualified_ref
    end

    rectify_format!

    rectify_renamed_default_branch! && return

    raise InvalidPathError unless @commit

    @hex_path = Digest::SHA1.hexdigest(@path)
    @logs_path = logs_file_project_ref_path(@project, @ref, @path)
  rescue RuntimeError, NoMethodError, InvalidPathError
    render_404
  end

  def ref_type
    ExtractsRef::RefExtractor.ref_type(params[:ref_type])
  end

  private

  # Override in controllers to determine which actions are subject to the redirect
  def redirect_renamed_default_branch?
    false
  end

  def rectify_format!
    return if @commit || @path.present?

    bare_ref, format = extract_ref_and_format(@id)
    return unless format

    @id = @ref = bare_ref
    @fully_qualified_ref = ExtractsRef::RefExtractor.qualify_ref(@ref, ref_type)
    @commit = @repo.commit(@fully_qualified_ref)

    return unless @commit

    request.format = format
  end

  # If we have an ID of 'foo.atom' or 'foo.json', and the controller provides
  # Atom, JSON, and HTML formats, then we have to check if the request was for
  # the Atom version of the ID without the '.atom' suffix, the JSON version of
  # the ID without the '.json' suffix, or the HTML version of the ID including
  # the suffix. We only check this if the version including the suffix doesn't
  # match, so it is possible to create a branch which has an unroutable Atom
  # feed or JSON view.
  def extract_ref_and_format(id)
    return [id, nil] unless id.match?(/\.(?:atom|json)$/)

    id, _dot, format = id.rpartition('.')
    ref = ref_names.find { |ref_name| id == ref_name }

    raise InvalidPathError if ref.blank?

    [ref, format.to_sym]
  end

  # For GET/HEAD requests, if the ref doesn't exist in the repository, check
  # whether we're trying to access a renamed default branch. If we are, we can
  # redirect to the current default branch instead of rendering a 404.
  def rectify_renamed_default_branch!
    return unless redirect_renamed_default_branch?
    return if @commit
    return unless @id && @ref && repository_container.respond_to?(:previous_default_branch)
    return unless repository_container.previous_default_branch == @ref
    return unless request.get? || request.head?

    flash[:notice] = _('The default branch for this project has been changed. Please update your bookmarks.')
    redirect_to url_for(id: @id.sub(/\A#{Regexp.escape(@ref)}/, repository_container.default_branch))

    true
  end

  def ref_names
    return [] unless repository_container

    @ref_names ||= repository_container.repository.ref_names
  end

  def repository_container
    @project
  end
end
# rubocop:enable Gitlab/ModuleWithInstanceVariables
