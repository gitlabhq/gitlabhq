# frozen_string_literal: true

module Gitlab
  module Housekeeper
    class Substitutor
      MR_WEB_URL_PLACEHOLDER = '<HOUSEKEEPER_MR_WEB_URL>'

      def self.perform(change)
        return unless change.mr_web_url.present?

        change.changed_files.each do |file|
          next unless File.file?(file)

          content = File.read(file)
          content.gsub!(MR_WEB_URL_PLACEHOLDER, change.mr_web_url)

          File.write(file, content)
        end
      end
    end
  end
end
