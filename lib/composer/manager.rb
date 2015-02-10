require 'digest'

module Composer
  class Manager

    BLANK_REPOSITORY = {"packages"=>[],"includes"=>{}}

    def initialize(project)
      @project = project
      @provider = Composer::Provider.new(project)
    end

    def add_package(package)

      raise 'package must be specified' unless package
      raise 'package must be of type Composer::Package' unless package.instance_of?(Composer::Package)

      @provider.add_package(package)
      @provider.save_or_delete

      update_repository

    end

    def rm_package(package)

      raise 'package must be specified' unless package
      raise 'package must be of type Composer::Package' unless package.instance_of?(Composer::Package)

      @provider.rm_package(package)
      @provider.save_or_delete

      update_repository

    end

    private

    def update_repository

      # load packages.json
      File.open(packages_json_file, "w") { |f| f.write(BLANK_REPOSITORY.to_json) } unless File.exist?(packages_json_file)
      includes = File.open(packages_json_file, "r") { |f| ActiveSupport::JSON.decode(f.read)["includes"] rescue {} }

      # process provider
      name = "/p/#{@provider.filename}"
      if @provider.has_packages?
        includes[name] ||= {}
        includes[name]["sha1"] = @provider.sha1
      else
        includes.delete(name)
      end

      # update packages.json
      content = {"packages"=>[],"includes"=>includes}.to_json
      File.open(packages_json_file, "w") { |f| f.write(content) }

    end

    def packages_json_file
      File.join(Rails.public_path, "/packages.json")
    end

  end
end