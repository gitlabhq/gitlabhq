module Projects
  module ImportExport
    class MembersMapper

      def self.map(*args)
        new(*args).map
      end

      def initialize(exported_members:)
        @exported_members = exported_members
      end

      def map
        #TODO
      end
    end
  end
end
