require 'open-uri'

module Gitlab
  module Ci
    module ExternalFiles
      class ExternalFile

        def initialize(value)
          @value = value
        end

        def content
          if remote_url?
            open(value).read
          else
            File.read(base_path)
          end
        end

        def valid?
          remote_url? || File.exists?(base_path) 
        end

        private

        attr_reader :value

        def base_path
          "#{Rails.root}/#{value}"
        end

        def remote_url?
          ::Gitlab::UrlSanitizer.valid?(value)
        end
      end
    end
  end
end
