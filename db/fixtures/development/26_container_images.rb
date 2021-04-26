# frozen_string_literal: true

class Gitlab::Seeder::ContainerImages
  attr_reader :tmp_dir, :project, :images_count

  DOCKER_FILE_CONTENTS = <<~EOS
    FROM scratch
    ARG tag
    ENV tag=$tag
  EOS

  def initialize(project, images_count)
    @project = project
    @images_count = images_count
    initialize_tmp_dir
  end

  def seed!
    images_count.times do |i|
      image_path = "#{project.container_registry_url}:tag_#{i}"
      build_image(image_path)
      push_image(image_path)
      puts '.'
    end
  ensure
    FileUtils.remove_entry tmp_dir
  end

  private

  def build_image(image_path)
    system(*%W[docker build -t #{image_path} --build-arg tag=gitlab_container_image_seed .], chdir: @tmp_dir)
  end

  def push_image(image_path)
    system(*%W[docker push #{image_path}], chdir: @tmp_dir)
  end

  def initialize_tmp_dir
    @tmp_dir = Dir.mktmpdir('gitlab_seeder_container_images')

    File.write(File.join(@tmp_dir, 'Dockerfile'), DOCKER_FILE_CONTENTS)
  end
end

Gitlab::Seeder.quiet do
  flag = 'SEED_CONTAINER_IMAGES'

  if ENV[flag]
    admin_user = User.admins.first
    images_count = Integer(ENV[flag])

    Project.not_mass_generated.visible_to_user(admin_user).sample(1).each do |project|
      puts "\nSeeding #{images_count} container images to the '#{project.full_path}' project."

      seeder = Gitlab::Seeder::ContainerImages.new(project, images_count)
      seeder.seed!
    rescue => e
      puts "\nSeeding container images failed with #{e.message}."
      puts "Make sure that the registry is running (https://gitlab.com/gitlab-org/gitlab-development-kit/blob/main/doc/howto/registry.md) and that Docker CLI (https://www.docker.com/products/docker-desktop) is installed."
    end
  else
    puts "Skipped. Use the `#{flag}` environment variable to seed container images to the registry."
  end
end
