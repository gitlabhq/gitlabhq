module Projects
  class PropagateService
    BATCH_SIZE = 100

    def self.propagate!(*args)
      new(*args).propagate!
    end

    def initialize(template)
      @template = template
    end

    def propagate!
      return unless @template&.active

      Rails.logger.info("Propagating services for template #{@template.id}")

      propagate_projects_with_template
    end

    private

    def propagate_projects_with_template
      offset = 0

      loop do
        batch = project_ids_batch(offset)

        batch.each { |project_id| create_from_template(project_id) }

        break if batch.count < BATCH_SIZE

        offset += BATCH_SIZE
      end
    end

    def create_from_template(project_id)
      Service.build_from_template(project_id, @template).save!
    end

    def project_ids_batch(offset)
      Project.joins('LEFT JOIN services ON services.project_id = projects.id').
        where('services.type != ? OR services.id IS NULL', @template.type).
        limit(BATCH_SIZE).offset(offset).pluck(:id)
    end
  end
end
