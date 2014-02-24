module Gitlab
  class ServiceDoc
    DOC_DIR = Rails.root.join("doc","services").freeze
    class << self
      def load
        @docs = {}
        if File.exists? DOC_DIR
          Dir.foreach(DOC_DIR) do |name|
            next if name == '.' or name == '..'
            @docs[name] = File.read(File.join(DOC_DIR, name))
          end
        end
      end

      def get(name)
        @docs[name]
      end
    end
  end
end
