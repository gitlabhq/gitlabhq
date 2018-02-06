# Module providing methods for dealing with separating a tree-ish string and a
# file path string when combined in a request parameter
module ExtractsPath
  # Raised when given an invalid file path
  InvalidPathError = Class.new(StandardError)

  # Given a string containing both a Git tree-ish, such as a branch or tag, and
  # a filesystem path joined by forward slashes, attempts to separate the two.
  #
  # Expects a @project instance variable to contain the active project. This is
  # used to check the input against a list of valid repository refs.
  #
  # Examples
  #
  #   # No @project available
  #   extract_ref('master')
  #   # => ['', '']
  #
  #   extract_ref('master')
  #   # => ['master', '']
  #
  #   extract_ref("f4b14494ef6abf3d144c28e4af0c20143383e062/CHANGELOG")
  #   # => ['f4b14494ef6abf3d144c28e4af0c20143383e062', 'CHANGELOG']
  #
  #   extract_ref("v2.0.0/README.md")
  #   # => ['v2.0.0', 'README.md']
  #
  #   extract_ref('master/app/models/project.rb')
  #   # => ['master', 'app/models/project.rb']
  #
  #   extract_ref('issues/1234/app/models/project.rb')
  #   # => ['issues/1234', 'app/models/project.rb']
  #
  #   # Given an invalid branch, we fall back to just splitting on the first slash
  #   extract_ref('non/existent/branch/README.md')
  #   # => ['non', 'existent/branch/README.md']
  #
  # Returns an Array where the first value is the tree-ish and the second is the
  # path
  def extract_ref(id)
    pair = ['', '']

    return pair unless @project # rubocop:disable Gitlab/ModuleWithInstanceVariables

    if id =~ /^(\h{40})(.+)/
      # If the ref appears to be a SHA, we're done, just split the string
      pair = $~.captures
    else
      # Otherwise, attempt to detect the ref using a list of the project's
      # branches and tags

      # Append a trailing slash if we only get a ref and no file path
      id += '/' unless id.ends_with?('/')

      valid_refs = ref_names.select { |v| id.start_with?("#{v}/") }

      if valid_refs.length == 0
        # No exact ref match, so just try our best
        pair = id.match(%r{([^/]+)(.*)}).captures
      else
        # There is a distinct possibility that multiple refs prefix the ID.
        # Use the longest match to maximize the chance that we have the
        # right ref.
        best_match = valid_refs.max_by(&:length)
        # Partition the string into the ref and the path, ignoring the empty first value
        pair = id.partition(best_match)[1..-1]
      end
    end

    # Remove ending slashes from path
    pair[1].gsub!(%r{^/|/$}, '')

    pair
  end

  # If we have an ID of 'foo.atom', and the controller provides Atom and HTML
  # formats, then we have to check if the request was for the Atom version of
  # the ID without the '.atom' suffix, or the HTML version of the ID including
  # the suffix. We only check this if the version including the suffix doesn't
  # match, so it is possible to create a branch which has an unroutable Atom
  # feed.
  def extract_ref_without_atom(id)
    id_without_atom = id.sub(/\.atom$/, '')
    valid_refs = ref_names.select { |v| "#{id_without_atom}/".start_with?("#{v}/") }

    valid_refs.max_by(&:length)
  end

  # Assigns common instance variables for views working with Git tree-ish objects
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
  #
  # If there is no path and the ref doesn't exist in the repo, try to resolve
  # the ref without an '.atom' suffix. If _that_ ref is found, set the request's
  # format to Atom manually.
  #
  # Automatically renders `not_found!` if a valid tree path could not be
  # resolved (e.g., when a user inserts an invalid path or ref).
  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def assign_ref_vars
    # assign allowed options
    allowed_options = ["filter_ref"]
    @options = params.select {|key, value| allowed_options.include?(key) && !value.blank? }
    @options = HashWithIndifferentAccess.new(@options)

    @id = get_id
    @ref, @path = extract_ref(@id)
    @repo = @project.repository

    @commit = @repo.commit(@ref)

    if @path.empty? && !@commit && @id.ends_with?('.atom')
      @id = @ref = extract_ref_without_atom(@id)
      @commit = @repo.commit(@ref)

      request.format = :atom if @commit
    end

    raise InvalidPathError unless @commit

    @hex_path = Digest::SHA1.hexdigest(@path)
    @logs_path = logs_file_project_ref_path(@project, @ref, @path)
  rescue RuntimeError, NoMethodError, InvalidPathError
    render_404
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  def tree
    @tree ||= @repo.tree(@commit.id, @path) # rubocop:disable Gitlab/ModuleWithInstanceVariables
  end

  def lfs_blob_ids
    blob_ids = tree.blobs.map(&:id)
    @lfs_blob_ids = Gitlab::Git::Blob.batch_lfs_pointers(@project.repository, blob_ids).map(&:id) # rubocop:disable Gitlab/ModuleWithInstanceVariables
  end

  private

  # overriden in subclasses, do not remove
  def get_id
    id = params[:id] || params[:ref]
    id += "/" + params[:path] unless params[:path].blank?
    id
  end

  def ref_names
    return [] unless @project # rubocop:disable Gitlab/ModuleWithInstanceVariables

    @ref_names ||= @project.repository.ref_names # rubocop:disable Gitlab/ModuleWithInstanceVariables
  end
end
