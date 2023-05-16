# frozen_string_literal: true

module Gitlab
  module GithubGistsImport
    module Representation
      class Gist
        include Gitlab::GithubImport::Representation::ToHash
        include Gitlab::GithubImport::Representation::ExposeAttribute

        attr_reader :attributes

        expose_attribute :id, :description, :is_public, :created_at, :updated_at, :files, :git_pull_url

        # Builds a gist from a GitHub API response.
        #
        # gist - An instance of `Hash` containing the gist
        #         details.
        def self.from_api_response(gist, additional_data = {})
          hash = {
            id: gist[:id],
            description: gist[:description],
            is_public: gist[:public],
            files: gist[:files],
            git_pull_url: gist[:git_pull_url],
            created_at: gist[:created_at],
            updated_at: gist[:updated_at]
          }

          new(hash)
        end

        # Builds a new gist using a Hash that was built from a JSON payload.
        def self.from_json_hash(raw_hash)
          new(Gitlab::GithubImport::Representation.symbolize_hash(raw_hash))
        end

        # attributes - A hash containing the raw gist details. The keys of this
        #              Hash (and any nested hashes) must be symbols.
        def initialize(attributes)
          @attributes = attributes
        end

        # Gist description can be an empty string, so we returning nil to use first file
        # name as a title in such case on snippet creation
        # Gist description has a limit of 256, while the snippet's title can be up to 255
        def truncated_title
          title = description.presence || first_file[:file_name]

          title.truncate(255)
        end

        def visibility_level
          is_public ? Gitlab::VisibilityLevel::PUBLIC : Gitlab::VisibilityLevel::PRIVATE
        end

        def first_file
          _key, value = files.first

          {
            file_name: value[:filename],
            file_content: Gitlab::HTTP.try_get(value[:raw_url])&.body
          }
        end

        def github_identifiers
          { id: id }
        end

        def total_files_size
          files.values.sum { |f| f[:size].to_i }
        end
      end
    end
  end
end
