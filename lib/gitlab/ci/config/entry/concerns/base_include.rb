# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        module Concerns
          ##
          # Module that provides common validation logic for include entries
          #
          # This module is included by:
          # - Gitlab::Ci::Config::Entry::Include
          # - Gitlab::Ci::Config::Header::Include
          #
          # This module is tested indirectly through the classes that include it.
          #
          module BaseInclude
            extend ActiveSupport::Concern

            COMMON_ALLOWED_KEYS = %i[local file remote project ref integrity].freeze

            included do
              include ::Gitlab::Config::Entry::Validatable
              include ::Gitlab::Config::Entry::Attributable

              attributes :local, :file, :remote, :project, :ref, :component, :integrity

              validations do
                validates :config, hash_or_string: true

                validate do
                  next unless config.is_a?(Hash)

                  if config[:project] && config[:file].blank?
                    errors.add(:config, "must specify the file where to fetch the config from")
                  end

                  if config[:integrity]
                    errors.add(:config, "integrity can only be specified for remote includes") if config[:remote].blank?

                    unless config[:integrity].is_a?(String) && config[:integrity].start_with?('sha256-')
                      errors.add(:config, "integrity hash must start with 'sha256-'")
                      next
                    end

                    hash = config[:integrity].delete_prefix('sha256-')
                    begin
                      Base64.strict_decode64(hash)
                    rescue ArgumentError
                      errors.add(:config, "integrity hash must be base64 encoded")
                    end
                  end
                end
              end
            end

            def skip_config_hash_validation?
              true
            end
          end
        end
      end
    end
  end
end
