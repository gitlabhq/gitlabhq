class BlobViewerEntity < Grape::Entity
  include RequestAwareEntity

  expose :type
  expose :partial_name, as: :name
  expose :switcher_title, :switcher_icon
  expose :load_async?, as: :server_side
  expose :render_error

  expose :render_error_reason do |viewer|
    BlobHelper.blob_render_error_reason(viewer)
  end

  expose :path do |viewer|
    url_for(request.params.merge(viewer: viewer.type, format: :json, only_path: true))
  end
end
