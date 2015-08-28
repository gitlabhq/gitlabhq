require 'digest/crc32'

module Gitlab
  module Composer
    module Repository
      class ProjectRepository < ::Composer::Repository::WritableHashRepository

        # Initializes the project repository.
        # @param [Composer::Json::JsonFile] repository_file The repository json file
        def initialize(repository_file)
          unless repository_file
            raise ArgumentError,
                  'repository_file must be specified'
          end
          unless repository_file.is_a?(::Composer::Json::JsonFile)
            raise TypeError,
                  'repository_file type must be a \
                  Composer::Json::JsonFile or superclass'
          end
          super([])
          @file = repository_file
          @dumper = ::Composer::Package::Dumper::HashDumper.new
        end

        def reload
          @packages = nil
          initialize_repository
        end

        # Writes the project repository to the filesystem.
        def write
          data = {}
          unless packages.nil? || packages.empty?
            uid = 0
            crc = Digest::CRC32.hexdigest(packages[0].name)
            packages.each do |package|
              next if package.instance_of?(::Composer::Package::AliasPackage)
              data[package.pretty_name] = {} unless data[package.pretty_name]
              data[package.pretty_name][package.pretty_version] = @dumper.dump(package)
              data[package.pretty_name][package.pretty_version]['uid'] = "#{crc}" + (uid += 1).to_s
            end
          end
          @file.write({ 'packages' => data })
        rescue Exception => e
          Gitlab::AppLogger.error("ProjectRepository: #{e.message}")
        end

        protected

        # Initializes repository (reads file, or remote address).
        def initialize_repository
          super
          return unless @file.exists?

          begin
            data = @file.read
            unless data.is_a?(Hash)
              raise UnexpectedValueError,
                    'Could not parse package list from the repository'
            end
            unless data['packages'].is_a?(Hash)
              raise UnexpectedValueError,
                    'Could not parse package list from the repository'
            end
            packages = data['packages']
          rescue Exception => e
            raise InvalidRepositoryError,
                  "Invalid repository data in #{@file.path}, \
                  packages could not be loaded: \
                  [#{e.class}] #{e.message}"
          end
          loader = ::Composer::Package::Loader::HashLoader.new(nil, true)
          packages.each do |name, versions|
            versions.each do |version, package_data|
              package = loader.load(package_data)
              add_package(package)
            end
          end

        end
      end
    end
  end
end
