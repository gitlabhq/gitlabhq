module Composer
  class Provider

    BLANK_PROVIDER = {"packages"=>{}}

    def initialize(project)
      @project = project
    end

    def add_package(package)

      raise 'package must be specified' unless package
      raise 'package must be of type Composer::Package' unless package.instance_of?(Composer::Package)

      name = package.name
      version = package.version

      packages[name] ||= {}
      packages[name][version] = package

      if packages[name].length >= 2
        packages[name].keys.sort.each { |k| packages[name][k] = packages[name].delete k }
      end

    end

    def rm_package(package)

      raise 'package must be specified' unless package
      raise 'package must be of type Composer::Package' unless package.instance_of?(Composer::Package)

      name = package.name
      version = package.version

      if has_package?(name, version)
        packages[name].delete(version)
        if packages[name].empty?
          packages.delete(name)
        elsif packages[name].length >= 2
          packages[name].keys.sort.each { |k| packages[name][k] = packages[name].delete k }
        end
      end

    end

    def clear_packages
      @packages = {}
    end

    def has_package?(name, version=nil)
      if version
        packages.key?(name) ? packages[name].key?(version) : false
      else
        packages.key?(name)
      end
    end

    def has_packages?
      !packages.empty?
    end

    def save_or_delete
      if has_packages?
        File.open(filepath, "w") { |f| f.write(content) }
      else
        File.delete(filepath) unless not File.exist?(filepath)
      end
    end

    def filename
      "project-#{@project.id}.json"
    end

    def sha1
      Digest::SHA1.hexdigest content
    end

    private

    def packages
      @packages ||= File.exist?(filepath) ? File.open(filepath, "r") { |f| ActiveSupport::JSON.decode(f.read)["packages"] rescue {} } : {}
    end

    def content
      {'packages' => packages}.to_json
    end

    def filepath
       File.join(File.realpath(Rails.root.join('public', 'p')), filename)
    end

  end
end
