# frozen_string_literal: true

class Gitlab::Seeder::Packages
  attr_reader :project

  def initialize(project)
    @project = project
  end

  def seed_packages(package_type)
    send("seed_#{package_type}_packages")
  end

  def seed_npm_packages
    5.times do |i|
      name = "@#{@project.root_namespace.path}/npm_package_#{SecureRandom.hex}"
      version = "1.12.#{i}"

      params = Gitlab::Json.parse(read_fixture_file('npm', 'payload.json')
          .gsub('@root/npm-test', name)
          .gsub('1.0.1', version))
        .with_indifferent_access

      ::Packages::Npm::CreatePackageService.new(project, project.creator, params).execute

      print '.'
    end
  end

  def seed_maven_packages
    5.times do |i|
      name = "my/company/app/maven-app-#{i}"
      version = "1.0.#{i}-SNAPSHOT"

      params = {
        name: name,
        version: version,
        path: "#{name}/#{version}"
      }

      pkg = ::Packages::Maven::CreatePackageService.new(project, project.creator, params).execute

      %w(maven-metadata.xml my-app-1.0-20180724.124855-1.pom my-app-1.0-20180724.124855-1.jar).each do |filename|
        with_cloned_fixture_file('maven', filename) do |filepath|
          file_params = {
            file: UploadedFile.new(filepath, filename: filename),
            file_name: filename,
            file_sha1: '1234567890',
            size: 100.kilobytes
          }
          ::Packages::CreatePackageFileService.new(pkg, file_params).execute
        end
      end

      print '.'
    end
  end

  def seed_conan_packages
    5.times do |i|
      name = "my-conan-pkg-#{i}"
      version = "2.0.#{i}"

      params = {
        package_name: name,
        package_version: version,
        package_username: ::Packages::Conan::Metadatum.package_username_from(full_path: project.full_path),
        package_channel: 'stable'
      }

      pkg = ::Packages::Conan::CreatePackageService.new(project, project.creator, params).execute

      fixtures = {
        'recipe_files' => %w(conanfile.py conanmanifest.txt),
        'package_files' => %w(conanmanifest.txt conaninfo.txt conan_package.tgz)
      }

      fixtures.each do |folder, filenames|
        filenames.each do |filename|
          with_cloned_fixture_file(File.join('conan', folder), filename) do |filepath|
            file = UploadedFile.new(filepath, filename: filename)
            file_params = {
              file_name: filename,
              'file.sha1': '1234567890',
              'file.size': 100.kilobytes,
              'file.md5': '12345',
              recipe_revision: '0',
              package_revision: '0',
              conan_package_reference: '123456789',
              conan_file_type: :package_file
            }
            ::Packages::Conan::CreatePackageFileService.new(pkg, file, file_params).execute
          end
        end
      end

      print '.'
    end
  end

  def seed_nuget_packages
    5.times do |i|
      name = "MyNugetApp.Package#{i}"
      version = "4.2.#{i}"

      pkg = ::Packages::CreateTemporaryPackageService.new(
        project, project.creator, {}
      ).execute(:nuget, name: Packages::Nuget::TEMPORARY_PACKAGE_NAME)
      # when using ::Packages::CreateTemporaryPackageService, packages have a fixed name and a fixed version.
      pkg.update!(name: name, version: version)

      filename = 'package.nupkg'
      with_cloned_fixture_file('nuget', filename) do |filepath|
        file_params = {
          file: UploadedFile.new(filepath, filename: filename),
          file_name: filename,
          file_sha1: '1234567890',
          size: 100.kilobytes
        }
        ::Packages::CreatePackageFileService.new(pkg, file_params).execute
      end

      print '.'
    end
  end

  private

  def read_fixture_file(package_type, file)
    File.read(fixture_path(package_type, file))
  end

  def fixture_path(package_type, file)
    Rails.root.join('spec', 'fixtures', 'packages', package_type, file)
  end

  def with_cloned_fixture_file(package_type, file)
    Dir.mktmpdir do |dirpath|
      cloned_path = File.join(dirpath, file)
      FileUtils.cp(fixture_path(package_type, file), cloned_path)
      yield cloned_path
    end
  end
end

Gitlab::Seeder.quiet do
  flag = 'SEED_ALL_PACKAGE_TYPES'

  puts "Use the `#{flag}` environment variable to seed packages of all types." unless ENV[flag]

  package_types = ENV[flag] ? %i[npm maven conan nuget] : [:npm]

  Project.not_mass_generated.sample(5).each do |project|
    puts "\nSeeding packages for the '#{project.full_path}' project"
    seeder = Gitlab::Seeder::Packages.new(project)

    package_types.each do |package_type|
      seeder.seed_packages(package_type)
    end
  end
end
