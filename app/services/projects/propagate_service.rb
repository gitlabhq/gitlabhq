module Projects
  class PropagateService
    BATCH_SIZE = 100

    def self.propagate(*args)
      new(*args).propagate
    end

    def initialize(template)
      @template = template
    end

    def propagate
      return unless @template&.active

      Rails.logger.info("Propagating services for template #{@template.id}")

      propagate_projects_with_template
    end

    private

    def propagate_projects_with_template
      loop do
        batch = project_ids_batch

        bulk_create_from_template(batch)

        break if batch.size < BATCH_SIZE
      end
    end

    def bulk_create_from_template(batch)
      service_hash_list = batch.map do |project_id|
        service_hash.merge('project_id' => project_id)
      end

      Project.transaction do
        Service.create!(service_hash_list)
      end
    end

    def project_ids_batch
      Project.connection.execute(
        <<-SQL
          SELECT id
          FROM projects
          WHERE NOT EXISTS (
            SELECT true
            FROM services
            WHERE services.project_id = projects.id
            AND services.type = '#{@template.type}'
          )
          LIMIT #{BATCH_SIZE}
      SQL
      ).to_a.flatten
    end

    def service_hash
      @service_hash ||= @template.as_json(methods: :type).except('id', 'template')
    end
  end
end
