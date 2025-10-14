# frozen_string_literal: true

require "digest"

module FrontendIslandsSha
  # Frontend islands source directories to monitor
  FRONTEND_ISLANDS_FOLDERS = %w[
    ee/frontend_islands/apps/duo_next/src
  ].freeze

  # Configuration and dependency files that impact build
  FRONTEND_ISLANDS_FILES = %w[
    ee/frontend_islands/apps/duo_next/package.json
    ee/frontend_islands/apps/duo_next/yarn.lock
    ee/frontend_islands/apps/duo_next/vite.config.ts
    ee/frontend_islands/apps/duo_next/tsconfig.json
    ee/frontend_islands/apps/duo_next/tsconfig.app.json
    ee/frontend_islands/apps/duo_next/tsconfig.node.json
    ee/frontend_islands/apps/duo_next/components.json
    ee/frontend_islands/apps/duo_next/.prettierrc
    ee/frontend_islands/apps/duo_next/eslint.config.js
    ee/frontend_islands/apps/duo_next/postcss.config.cjs
    ee/frontend_islands/apps/duo_next/vitest.config.ts
  ].freeze

  # Source file patterns to include
  SOURCE_FILE_PATTERNS = %w[
    ee/frontend_islands/apps/duo_next/src/**/*.{vue,ts,js,css,json}
  ].freeze

  # Files and directories to exclude from hash calculation
  EXCLUDE_PATTERNS = %w[
    ee/frontend_islands/apps/duo_next/dist/**/*
    ee/frontend_islands/apps/duo_next/node_modules/**/*
    ee/frontend_islands/apps/duo_next/.vscode/**/*
    ee/frontend_islands/apps/duo_next/**/*.log
    ee/frontend_islands/apps/duo_next/**/.DS_Store
    ee/frontend_islands/apps/duo_next/.prettierignore
  ].freeze

  class << self
    def cached_frontend_islands_sha256
      @cached_frontend_islands_sha256 ||= ENV.fetch('GLCI_FRONTEND_ISLANDS_HASH_FILE',
        'cached-frontend-islands-hash.txt').then do |file|
        next 'missing!' unless File.exist?(file)

        File.read(file).strip
      end
    end

    def sha256_of_frontend_islands_impacting_compilation
      frontend_islands_sha256 = frontend_islands_impacting_compilation.map do |file|
        Digest::SHA256.file(file).hexdigest
      end.join

      Digest::SHA256.hexdigest(frontend_islands_sha256)
    end

    private

    def frontend_islands_impacting_compilation
      # Start with explicit configuration files
      files = FRONTEND_ISLANDS_FILES.select { |file| File.exist?(file) }

      # Add all source files matching patterns
      SOURCE_FILE_PATTERNS.each do |pattern|
        files.concat(Dir.glob(pattern))
      end

      # Filter out excluded patterns and non-existent files
      files = files.reject do |file|
        EXCLUDE_PATTERNS.any? { |pattern| File.fnmatch?(pattern, file) }
      end

      files.select { |file| File.exist?(file) && File.file?(file) }.sort.uniq
    end
  end
end

printf FrontendIslandsSha.sha256_of_frontend_islands_impacting_compilation if __FILE__ == $PROGRAM_NAME
