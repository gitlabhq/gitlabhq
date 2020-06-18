# frozen_string_literal: true

# Module providing methods for dealing with separating a tree-ish string and a
# file path string when combined in a request parameter
# Can be extended for different types of repository object, e.g. Project or Snippet
module ExtractsRef
  InvalidPathError = Class.new(StandardError)

  # Given a string containing both a Git tree-ish, such as a branch or tag, and
  # a filesystem path joined by forward slashes, attempts to separate the two.
  #
  # Expects a repository_container method that returns the active repository object. This is
  # used to check the input against a list of valid repository refs.
  #
  # Examples
  #
  #   # No repository_container available
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

    return pair unless repository_container

    if id =~ /^(\h{40})(.+)/
      # If the ref appears to be a SHA, we're done, just split the string
      pair = $~.captures
    else
      # Otherwise, attempt to detect the ref using a list of the repository_container's
      # branches and tags

      # Append a trailing slash if we only get a ref and no file path
      unless id.ends_with?('/')
        id = [id, '/'].join
      end

      valid_refs = ref_names.select { |v| id.start_with?("#{v}/") }

      if valid_refs.empty?
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

    pair[0] = pair[0].strip

    # Remove ending slashes from path
    pair[1].gsub!(%r{^/|/$}, '')

    pair
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
  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def assign_ref_vars
    @id = get_id
    @ref, @path = extract_ref(@id)
    @repo = repository_container.repository

    raise InvalidPathError if @ref.match?(/\s/)

    @commit = @repo.commit(@ref)
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  def tree
    @tree ||= @repo.tree(@commit.id, @path) # rubocop:disable Gitlab/ModuleWithInstanceVariables
  end

  private

  # overridden in subclasses, do not remove
  def get_id
    id = [params[:id] || params[:ref]]
    id << "/" + params[:path] unless params[:path].blank?
    id.join
  end

  def ref_names
    return [] unless repository_container

    @ref_names ||= repository_container.repository.ref_names # rubocop:disable Gitlab/ModuleWithInstanceVariables
  end

  def repository_container
    raise NotImplementedError
  end
end
