# frozen_string_literal: true

class ContainerRepositoriesSerializer < BaseSerializer
  include WithPagination
  entity ContainerRepositoryEntity

  def represent_read_only(resource)
    represent(resource, except: [:destroy_path])
  end
end
