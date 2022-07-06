# frozen_string_literal: true

module Terraform
  class ModuleVersionPresenter < Gitlab::View::Presenter::Simple
    attr_accessor :package, :system

    def initialize(package, system)
      @package = package
      @system = system
    end

    def name
      package.name
    end

    def provider
      system
    end

    def providers
      [
        provider
      ]
    end

    def root
      {
        'dependencies' => []
      }
    end

    def source
      package&.project&.web_url
    end

    def submodules
      []
    end

    def version
      package.version
    end

    def versions
      [
        version
      ]
    end
  end
end
