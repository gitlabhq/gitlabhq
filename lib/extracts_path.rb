# Module providing methods for dealing with separating a tree-ish string and a
# file path string when combined in a request parameter
module ExtractsPath
  extend ActiveSupport::Concern

  # Raised when given an invalid file path
  class InvalidPathError < StandardError; end

  included do
    if respond_to?(:before_filter)
      before_filter :assign_ref_vars
    end
  end

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

    return pair unless @project

    if id.match(/^([[:alnum:]]{40})(.+)/)
      # If the ref appears to be a SHA, we're done, just split the string
      pair = $~.captures
    else
      # Otherwise, attempt to detect the ref using a list of the project's
      # branches and tags

      # Append a trailing slash if we only get a ref and no file path
      id += '/' unless id.ends_with?('/')

      valid_refs = @project.repository.ref_names
      valid_refs.select! { |v| id.start_with?("#{v}/") }

      if valid_refs.length != 1
        # No exact ref match, so just try our best
        pair = id.match(/([^\/]+)(.*)/).captures
      else
        # Partition the string into the ref and the path, ignoring the empty first value
        pair = id.partition(valid_refs.first)[1..-1]
      end
    end

    # Remove ending slashes from path
    pair[1].gsub!(/^\/|\/$/, '')

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
  # Automatically renders `not_found!` if a valid tree path could not be
  # resolved (e.g., when a user inserts an invalid path or ref).
  def assign_ref_vars
    # assign allowed options
    allowed_options = ["filter_ref", "extended_sha1"]
    @options = params.select {|key, value| allowed_options.include?(key) && !value.blank? }
    @options = HashWithIndifferentAccess.new(@options)

    @id = get_id
    @ref, @path = extract_ref(@id)
    @repo = @project.repository
    if @options[:extended_sha1].blank?
      @commit = @repo.commit(@ref)
    else
      @commit = @repo.commit(@options[:extended_sha1])
    end

    raise InvalidPathError unless @commit

    @hex_path = Digest::SHA1.hexdigest(@path)
    @logs_path = logs_file_project_ref_path(@project, @ref, @path)

  rescue RuntimeError, NoMethodError, InvalidPathError
    not_found!
  end

  def tree
    @tree ||= @repo.tree(@commit.id, @path)
  end

  private

  def get_id
    id = params[:id] || params[:ref]
    id += "/" + params[:path] unless params[:path].blank?
    id
  end
end
