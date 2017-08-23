class BlobEntity < BlobBasicEntity
  expose :extension, :mime_type, :file_type

  expose :raw_size, as: :size
  expose :raw_binary?, as: :binary

  expose :simple_viewer, :rich_viewer, :auxiliary_viewer, using: BlobViewerEntity

  expose :stored_externally?, as: :stored_externally
  expose :expanded?, as: :expanded

  expose :raw_path do |blob|
    project_raw_path(request.project, File.join(request.ref, blob.path))
  end

  expose :blame_path do |blob|
    project_blame_path(request.project, File.join(request.ref, blob.path))
  end

  expose :commits_path do |blob|
    project_commits_path(request.project, File.join(request.ref, blob.path))
  end

  expose :tree_path do |blob|
    path_segments = blob.path.split('/')
    path_segments.pop
    tree_path = path_segments.join('/')

    project_tree_path(request.project, File.join(request.ref, tree_path))
  end

  expose :permalink do |blob|
    project_blob_path(request.project, File.join(request.commit.id, blob.path))
  end
end
