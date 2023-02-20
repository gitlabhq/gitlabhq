# frozen_string_literal: true

module Projects
  module ContainerRepository
    class DeleteTagsService < BaseService
      LOG_DATA_BASE = { service_class: self.to_s }.freeze

      def execute(container_repository)
        @container_repository = container_repository

        unless container_expiration_policy?
          return error('access denied') unless can?(current_user, :destroy_container_image, project)
        end

        @tag_names = params[:tags]
        return error('not tags specified') if @tag_names.blank?
        return error('repository importing') if cancel_while_importing?

        delete_tags
      end

      private

      def delete_tags
        delete_service
          .execute
          .tap { |response| log_response(response) }
      end

      def delete_service
        if @container_repository.client.supports_tag_delete?
          ::Projects::ContainerRepository::Gitlab::DeleteTagsService.new(@container_repository, @tag_names)
        else
          ::Projects::ContainerRepository::ThirdParty::DeleteTagsService.new(@container_repository, @tag_names)
        end
      end

      def log_response(response)
        log_data = LOG_DATA_BASE.merge(
          container_repository_id: @container_repository.id,
          project_id: @container_repository.project_id,
          message: 'deleted tags',
          deleted_tags_count: response[:deleted]&.size
        ).compact

        if response[:status] == :success
          log_info(log_data)
        else
          log_data[:message] = response[:message]
          log_error(log_data)
        end
      end

      def cancel_while_importing?
        return true if @container_repository.importing?

        if container_expiration_policy?
          return @container_repository.pre_importing? || @container_repository.pre_import_done?
        end

        false
      end

      def container_expiration_policy?
        params[:container_expiration_policy].present?
      end
    end
  end
end
