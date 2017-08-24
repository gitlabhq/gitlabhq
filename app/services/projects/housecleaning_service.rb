module Projects
  class HousecleaningService
    def self.reserved_refs_names
      %w[heads tags merge-requests keep-around environments]
    end

    def self.reserved_refs_regexp
      names = reserved_refs_names.map(&Regexp.method(:escape)).join('|')

      %r{\Arefs/(?:#{names})/}
    end

    def initialize(project)
      @project = project
    end

    # This could raise Projects::HousekeepingService::LeaseTaken
    def execute
      Projects::HousekeepingService.new(@project).execute do
        garbage_refs.each(&rugged.references.method(:delete))
      end
    end

    private

    def garbage_refs
      @garbage_refs ||= begin
        reserved_refs_regexp = self.class.reserved_refs_regexp

        rugged.references.reject do |ref|
          ref.name =~ reserved_refs_regexp
        end
      end
    end

    def rugged
      @rugged ||= @project.repository.rugged
    end
  end
end
