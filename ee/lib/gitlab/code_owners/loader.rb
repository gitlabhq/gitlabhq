# frozen_string_literal: true

module Gitlab
  module CodeOwners
    class Loader
      def initialize(project, ref, path)
        @project, @ref, @path = project, ref, path
      end

      def users
        return User.none if code_owners_file.empty?

        owners = code_owners_file.owners_for_path(@path)
        extracted_users = Gitlab::UserExtractor.new(owners).users

        @project.authorized_users.merge(extracted_users)
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
