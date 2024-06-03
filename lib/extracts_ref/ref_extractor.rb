# frozen_string_literal: true

# Module providing methods for dealing with separating a tree-ish string and a
# file path string when combined in a request parameter
# Can be extended for different types of repository object, e.g. Project or Snippet
module ExtractsRef
  class RefExtractor
    InvalidPathError = Class.new(StandardError)
    BRANCH_REF_TYPE = 'heads'
    TAG_REF_TYPE = 'tags'
    REF_TYPES = [BRANCH_REF_TYPE, TAG_REF_TYPE].freeze

    attr_reader :repository_container, :params
    attr_accessor :id, :ref, :commit, :path, :fully_qualified_ref, :repo

    class << self
      def ref_type(type)
        return unless REF_TYPES.include?(type.to_s.downcase)

        type.downcase
      end

      def qualify_ref(ref, type)
        validated_type = ref_type(type)
        return ref unless validated_type

        %(refs/#{validated_type}/#{ref})
      end

      def unqualify_ref(ref, type)
        validated_type = ref_type(type)
        return ref unless validated_type

        ref.sub(%r{^refs/#{validated_type}/}, '')
      end
    end

    def initialize(repository_container, params, override_id: nil)
      @repository_container = repository_container
      @params = params.slice(:id, :ref, :path, :ref_type)
      @override_id = override_id
    end

    # Extracts common variables for views working with Git tree-ish objects
    #
    # Assignments are:
    #
    # - @id     - A string representing the joined ref and path
    #             Assigns @override_id if it is present.
    # - @ref    - A string representing the ref (e.g., the branch, tag, or commit SHA)
    # - @path   - A string representing the filesystem path
    # - @commit - A Commit representing the commit from the given ref
    # - @fully_qualified_ref - A string representing the fully qualifed ref (e.g., refs/tags/v1.1)
    #
    # If the :id parameter appears to be requesting a specific response format,
    # that will be handled as well.
    def extract!
      qualified_id, @ref, @path = extract_ref_path
      @id = @override_id || qualified_id
      @repo = repository_container.repository
      raise InvalidPathError if @ref.match?(/\s/)

      return unless @ref.present?

      @commit = if ref_type
                  @fully_qualified_ref = self.class.qualify_ref(@ref, ref_type)
                  @repo.commit(@fully_qualified_ref)
                else
                  @repo.commit(@ref)
                end
    end

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
      pair = extract_raw_ref(id)

      [
        pair[0].strip,
        pair[1].delete_prefix('/').delete_suffix('/')
      ]
    end

    def ref_type
      self.class.ref_type(params[:ref_type])
    end

    private

    def extract_ref_path
      id = extract_id_from_params
      ref, path = extract_ref(id)

      [id, ref, path]
    end

    def extract_raw_ref(id)
      return ['', ''] unless repository_container

      # If the ref appears to be a SHA, we're done, just split the string
      return $~.captures if id =~ /^(\h{40}\h{24}?)(.*)/

      # No slash means we must have a ref and no path
      return [id, ''] unless id.include?('/')

      # Otherwise, attempt to detect the ref using a list of the
      # repository_container's branches and tags

      # Append a trailing slash if we only get a ref and no file path
      id = [id, '/'].join unless id.ends_with?('/')
      first_path_segment, rest = id.split('/', 2)

      return [first_path_segment, rest] if use_first_path_segment?(first_path_segment)

      valid_refs = ref_names.select { |v| id.start_with?("#{v}/") }

      # No exact ref match, so just try our best
      return id.match(%r{([^/]+)(.*)}).captures if valid_refs.empty?

      # There is a distinct possibility that multiple refs prefix the ID.
      # Use the longest match to maximize the chance that we have the
      # right ref.
      best_match = valid_refs.max_by(&:length)

      # Partition the string into the ref and the path, ignoring the empty first value
      id.partition(best_match)[1..]
    end

    def use_first_path_segment?(ref)
      return false unless repository_container
      return false if repository_container.repository.has_ambiguous_refs?

      repository_container.repository.branch_names_include?(ref) ||
        repository_container.repository.tag_names_include?(ref)
    end

    def extract_id_from_params
      id = [params[:id] || params[:ref]]
      id << ("/#{params[:path]}") unless params[:path].blank?
      id.join
    end

    def ref_names
      return [] unless repository_container

      @ref_names ||= repository_container.repository.ref_names
    end
  end
end
