module Gitlab
  module GitoriousImport
    Repository = Struct.new(:full_name) do
      def id
        Digest::SHA1.hexdigest(full_name)
      end

      def namespace
        segments.first
      end

      def path
        segments.last
      end

      def name
        path.titleize
      end

      def description
        ""
      end

      def import_url
        "#{GITORIOUS_HOST}/#{full_name}.git"
      end

      private

      def segments
        full_name.split('/')
      end
    end
  end
end
