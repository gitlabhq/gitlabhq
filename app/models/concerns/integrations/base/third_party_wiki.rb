# frozen_string_literal: true

module Integrations
  module Base
    module ThirdPartyWiki
      extend ActiveSupport::Concern
      include SafeFormatHelper

      class_methods do
        def supported_events
          %w[]
        end
      end

      included do
        attribute :category, default: 'third_party_wiki'

        validate :only_one_third_party_wiki, if: :activated?, on: :manual_change

        after_commit :cache_project_has_integration
      end

      private

      def only_one_third_party_wiki
        return unless project_level?

        return if project.integrations.third_party_wikis.id_not_in(id).empty?

        errors.add(:base, _('Another third-party wiki is already in use. ' \
          'Only one third-party wiki integration can be active at a time'))
      end

      def cache_project_has_integration
        return unless project && !project.destroyed?

        project_setting = project.project_setting

        project_setting.public_send(:"#{project_settings_cache_key}=", active?) # rubocop:disable GitlabSecurity/PublicSend -- Legacy use
        project_setting.save!
      end

      def project_settings_cache_key
        "has_#{self.class.to_param}"
      end
    end
  end
end
