# frozen_string_literal: true

require "digest"
require_relative "gitlab"

module AssetsSha
  FOSS_ASSET_FOLDERS = %w[app/assets fixtures/emojis vendor/assets].freeze
  EE_ASSET_FOLDERS = %w[ee/app/assets].freeze
  JH_ASSET_FOLDERS = %w[jh/app/assets].freeze
  PUBLIC_ASSETS_DIR = 'public/assets'

  # In the new caching strategy, we check the assets hash sum *before* compiling
  # the app/assets/javascripts/locale/**/app.js files. That means the hash sum
  # must depend on locale/**/gitlab.po.
  JS_ASSET_PATTERNS = %w[*.js config/**/*.js scripts/frontend/*.{mjs,js} locale/**/gitlab.po].freeze

  JS_ASSET_FILES = %w[
    package.json
    yarn.lock
    babel.config.js
    .nvmrc
  ].freeze

  # Ruby gems might emit assets which have an impact on compilation
  # or have a direct impact on asset compilation (e.g. scss) and therefore
  # we should compile when these change
  RAILS_ASSET_FILES = %w[
    config/application.rb
    Gemfile
    Gemfile.lock
  ].freeze

  EXCLUDE_PATTERNS = %w[
    app/assets/javascripts/locale/**/app.js
  ].freeze

  class << self
    def cached_assets_sha256
      @cached_assets_sha256 ||= ENV.fetch('GLCI_GITLAB_ASSETS_HASH_FILE', 'cached-assets-hash.txt').then do |file|
        next 'missing!' unless File.exist?(file)

        File.read(file).strip
      end
    end

    def sha256_of_assets_impacting_compilation
      assets_sha256 = assets_impacting_compilation.map { |asset_file| Digest::SHA256.file(asset_file).hexdigest }.join

      Digest::SHA256.hexdigest(assets_sha256)
    end

    private

    # Files listed here should match the list in:
    # .assets-compilation-patterns in .gitlab/ci/rules.gitlab-ci.yml
    # So we make sure that any impacting changes we do rebuild cache
    def assets_impacting_compilation
      assets_folders = FOSS_ASSET_FOLDERS
      assets_folders += EE_ASSET_FOLDERS if ::Gitlab.ee?
      assets_folders += JH_ASSET_FOLDERS if ::Gitlab.jh?

      asset_files = Dir.glob(JS_ASSET_PATTERNS)
      asset_files += JS_ASSET_FILES
      asset_files += RAILS_ASSET_FILES

      assets_folders.each do |folder|
        asset_files.concat(Dir.glob(["#{folder}/**/*.*"]))
      end

      asset_files - Dir.glob(EXCLUDE_PATTERNS)
    end
  end
end

printf AssetsSha.sha256_of_assets_impacting_compilation if __FILE__ == $PROGRAM_NAME
