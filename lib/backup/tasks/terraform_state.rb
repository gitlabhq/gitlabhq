# frozen_string_literal: true

module Backup
  module Tasks
    class TerraformState < Task
      def self.id = 'terraform_state'

      def human_name = _('terraform states')

      def destination_path = 'terraform_state.tar.gz'

      private

      def target
        @target ||= ::Backup::Targets::Files.new(progress, storage_path, options: options, excludes: ['tmp'])
      end

      def storage_path
        Settings.terraform_state.storage_path
      end
    end
  end
end
