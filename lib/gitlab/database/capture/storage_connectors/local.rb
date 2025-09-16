# frozen_string_literal: true

module Gitlab
  module Database
    module Capture
      module StorageConnectors
        # To simplify testing and development
        class Local
          TEMP_PATH = Rails.root.join('tmp/database-traffic-capture/storage')

          def initialize(settings)
            unless Rails.env.development? || Rails.env.test?
              raise ConfigurationError, "Local connector provider it's not intended to be used in production"
            end

            @settings = settings
          end

          def upload(filename, data)
            Gitlab::PathTraversal.check_path_traversal!(filename)

            filepath = Rails.root.join(TEMP_PATH, File.basename(filename))

            Gitlab::PathTraversal.check_allowed_absolute_path!(File.dirname(filepath), [TEMP_PATH.to_s])

            FileUtils.mkdir_p(File.dirname(filepath))

            File.open(filepath, 'w') do |file|
              file.write(data)
            end
          end
        end
      end
    end
  end
end
