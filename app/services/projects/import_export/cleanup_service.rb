module Projects
  module ImportExport
    class CleanupService
      RESERVED_REFS_REGEXP =
        %r{\Arefs/(?:heads|tags|merge\-requests|keep\-around|environments)/}

      attr_reader :project

      def initialize(project)
        @project = project
      end

      # This could raise Projects::HousekeepingService::LeaseTaken
      def execute
        Projects::HousekeepingService.new(project).execute do
          garbage_refs.each(&rugged.references.method(:delete))
        end
      end

      private

      def garbage_refs
        @garbage_refs ||= rugged.references.reject do |ref|
          ref.name =~ RESERVED_REFS_REGEXP
        end
      end

      def rugged
        @rugged ||= project.repository.rugged
      end
    end
  end
end
