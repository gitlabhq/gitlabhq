# frozen_string_literal: true

require "digest"

module FrontendIslandsSha
  # Configuration and dependency files that impact build
  FRONTEND_ISLANDS_FILES = %w[
    ee/frontend_islands/apps/**/package.json
    ee/frontend_islands/apps/**/vite.config.ts
    ee/frontend_islands/apps/**/tsconfig.json
    ee/frontend_islands/apps/**/tsconfig.app.json
    ee/frontend_islands/apps/**/tsconfig.node.json
    ee/frontend_islands/apps/**/components.json
    ee/frontend_islands/apps/**/.prettierrc
    ee/frontend_islands/apps/**/eslint.config.js
    ee/frontend_islands/apps/**/postcss.config.cjs
    ee/frontend_islands/apps/**/vitest.config.ts
    ee/frontend_islands/packages/configs/**/package.json
    ee/frontend_islands/packages/configs/**/index.{js,json}
    ee/frontend_islands/packages/configs/**/tsconfig.{,app,node}json
  ].freeze

  # Source file patterns to include
  SOURCE_FILE_PATTERNS = %w[
    ee/frontend_islands/apps/**/src/**/*.{vue,ts,js,css,json}
  ].freeze

  # Files and directories to exclude from hash calculation
  EXCLUDE_PATTERNS = %w[
    ee/frontend_islands/**/dist/**/*
    ee/frontend_islands/**/node_modules/**/*
    ee/frontend_islands/**/.vscode/**/*
    ee/frontend_islands/**/**/*.log
    ee/frontend_islands/**/**/.DS_Store
    ee/frontend_islands/**/.prettierignore
    ee/frontend_islands/**/*.md
    ee/frontend_islands/**/*.md
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
