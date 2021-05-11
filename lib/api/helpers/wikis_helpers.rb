# frozen_string_literal: true

module API
  module Helpers
    module WikisHelpers
      def self.wiki_resource_kinds
        [:projects]
      end

      def find_container(kind)
        return user_project if kind == :projects

        raise "Unknown wiki container #{kind}"
      end

      def wiki_page
        Wiki.for_container(container, current_user).find_page(params[:slug]) || not_found!('Wiki Page')
      end

      def commit_params(attrs)
        base_params = { branch_name: attrs[:branch] }
        file_details = case attrs[:file]
                       when Hash # legacy format: TODO remove when we drop support for non accelerated uploads
                         { file_name: attrs[:file][:filename], file_content: attrs[:file][:tempfile].read }
                       else
                         { file_name: attrs[:file].original_filename, file_content: attrs[:file].read }
                       end

        base_params.merge(file_details)
      end
    end
  end
end

API::Helpers::WikisHelpers.prepend_mod_with('API::Helpers::WikisHelpers')
