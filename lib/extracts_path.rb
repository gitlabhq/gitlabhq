# frozen_string_literal: true

# Module providing methods for dealing with separating a tree-ish string and a
# file path string when combined in a request parameter
module ExtractsPath
  extend ::Gitlab::Utils::Override
  include ExtractsRef

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

  # Extends the method to handle if there is no path and the ref doesn't
  # exist in the repo, try to resolve the ref without an '.atom' suffix.
  # If _that_ ref is found, set the request's format to Atom manually.
  #
  # Automatically renders `not_found!` if a valid tree path could not be
  # resolved (e.g., when a user inserts an invalid path or ref).
  #
  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  override :assign_ref_vars
  def assign_ref_vars
    super

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

  def lfs_blob_ids
    blob_ids = tree.blobs.map(&:id)

    # When current endpoint is a Blob then `tree.blobs` will be empty, it means we need to analyze
    # the current Blob in order to determine if it's a LFS object
    blob_ids = Array.wrap(@repo.blob_at(@commit.id, @path)&.id) if blob_ids.empty? # rubocop:disable Gitlab/ModuleWithInstanceVariables

    @lfs_blob_ids = Gitlab::Git::Blob.batch_lfs_pointers(repository_container.repository, blob_ids).map(&:id) # rubocop:disable Gitlab/ModuleWithInstanceVariables
  end

  private

  override :repository_container
  def repository_container
    @project
  end
end
