# frozen_string_literal: true

module Sbom
  module PurlType
    class Converter
      PACKAGE_MANAGER_TO_PURL_TYPE_MAP = {
        'bundler' => 'gem',
        'yarn' => 'npm',
        'npm' => 'npm',
        'pnpm' => 'npm',
        'maven' => 'maven',
        'sbt' => 'maven',
        'gradle' => 'maven',
        'composer' => 'composer',
        'conan' => 'conan',
        'go' => 'golang',
        'nuget' => 'nuget',
        'pip' => 'pypi',
        'pipenv' => 'pypi',
        'setuptools' => 'pypi'
      }.with_indifferent_access.freeze

      def self.purl_type_for_pkg_manager(package_manager)
        PACKAGE_MANAGER_TO_PURL_TYPE_MAP[package_manager]
      end
    end
  end
end
