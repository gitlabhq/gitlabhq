# frozen_string_literal: true

module Gitlab
  module CodeOwners
    class Loader
      def initialize(project, ref, paths)
        @project, @ref, @paths = project, ref, Array(paths)
      end

      def members
        @_members ||= @project.members_among(raw_users)
      end

      def non_members
        @_non_members ||= raw_users.where_not_in(@project.authorized_users)
      end

      def raw_users
        return User.none if empty_code_owners? # rubocop: disable CodeReuse/ActiveRecord

        @_raw_users ||= begin
          owner_lines = @paths.map { |path| code_owners_file.owners_for_path(path) }

          Gitlab::UserExtractor.new(owner_lines).users
        end
      end

      def empty_code_owners?
        code_owners_file.empty?
      end

      private

      def code_owners_file
        if RequestStore.active?
          RequestStore.fetch("project-#{@project.id}:code-owners:#{@ref}") do
            load_code_owners_file
          end
        else
          load_code_owners_file
        end
      end

      def load_code_owners_file
        code_owners_blob = @project.repository.code_owners_blob(ref: @ref)
        Gitlab::CodeOwners::File.new(code_owners_blob)
      end
    end
  end
end
