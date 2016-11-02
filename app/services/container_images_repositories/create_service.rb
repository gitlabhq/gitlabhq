module ContainerImagesRepositories
  class CreateService < BaseService
    def execute
      project.container_images_repository || ::ContainerImagesRepository.create(project: project)
    end
  end
end
