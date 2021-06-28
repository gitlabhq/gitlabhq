# frozen_string_literal: true

# Serializes diffs with pagination data.
#
# Avoid adding more keys to this serializer as processing the
# diff file serialization is not cheap.
#
class PaginatedDiffEntity < Grape::Entity
  include RequestAwareEntity
  include DiffHelper

  expose :diff_files do |diffs, options|
    submodule_links = Gitlab::SubmoduleLinks.new(merge_request.project.repository)

    DiffFileEntity.represent(
      diffs.diff_files(sorted: true),
      options.merge(
        submodule_links: submodule_links,
        code_navigation_path: code_navigation_path(diffs),
        conflicts: conflicts
      )
    )
  end

  expose :pagination do
    expose :total_pages do |diffs, options|
      options.dig(:pagination_data, :total_pages)
    end
  end

  private

  def merge_request
    options[:merge_request]
  end
end
