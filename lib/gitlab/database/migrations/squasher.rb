# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      class Squasher
        RSPEC_FILENAME_REGEXP = /\A([0-9]+_)?([_a-z0-9]*)\.rb\z/

        def initialize(git_output)
          @migration_data = migration_files_from_git(git_output).filter_map do |mf|
            basename = Pathname(mf).basename.to_s
            file_name_match = ActiveRecord::Migration::MigrationFilenameRegexp.match(basename)
            slug = file_name_match[2]
            unless slug == 'init_schema'
              {
                path: mf,
                basename: basename,
                timestamp: file_name_match[1],
                slug: slug
              }
            end
          end
        end

        def files_to_delete
          @migration_data.pluck(:path) + schema_migrations + find_migration_specs
        end

        private

        def schema_migrations
          @migration_data.map { |m| "db/schema_migrations/#{m[:timestamp]}" }
        end

        def find_migration_specs
          @file_slugs = Set.new @migration_data.pluck(:slug)
          (migration_specs + ee_migration_specs).select { |f| file_has_slug?(f) }
        end

        def migration_files_from_git(body)
          body.chomp
              .split("\n")
              .select { |fn| fn.end_with?('.rb') }
        end

        def match_file_slug(filename)
          m = RSPEC_FILENAME_REGEXP.match(filename)
          return if m.nil?

          m[2].sub(/_spec$/, '')
        end

        def file_has_slug?(filename)
          spec_slug = match_file_slug(Pathname(filename).basename.to_s)
          return false if spec_slug.nil?

          @file_slugs.include?(spec_slug)
        end

        def migration_specs
          Dir.glob(Rails.root.join('spec/migrations/*.rb'))
        end

        def ee_migration_specs
          Dir.glob(Rails.root.join('ee/spec/migrations/*.rb'))
        end
      end
    end
  end
end
