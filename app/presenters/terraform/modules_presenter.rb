# frozen_string_literal: true

module Terraform
  class ModulesPresenter < Gitlab::View::Presenter::Simple
    attr_accessor :packages, :system

    presents :modules

    def initialize(packages, system)
      @packages = packages
      @system = system
    end

    def modules
      project_url = @packages.first&.project&.web_url
      versions = @packages.map do |package|
        {
          'version' => package.version,
          'submodules' => [],
          'root' => {
            'dependencies' => [],
            'providers' => [
              {
                'name' => @system,
                'version' => ''
              }
            ]
          }
        }
      end

      [
        {
          'versions' => versions,
          'source' => project_url
        }.compact
      ]
    end
  end
end
