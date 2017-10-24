class SubmoduleEntity < Grape::Entity
  include RequestAwareEntity

  expose :id, :path, :name, :mode

  expose :icon do |blob|
    'archive'
  end

  expose :url do |blob|
    submodule_links(blob, request).first
  end

  expose :tree_url do |blob|
    submodule_links(blob, request).last
  end

  private

  def submodule_links(blob, request)
    @submodule_links ||= SubmoduleHelper.submodule_links(blob, request.ref, request.repository)
  end
end
