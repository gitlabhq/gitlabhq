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

        bulk_create_from_template(batch) unless batch.empty?

        break if batch.size < BATCH_SIZE
      end
    end

    def bulk_create_from_template(batch)
      service_list = batch.map do |project_id|
        service_hash.merge('project_id' => project_id).values
      end

      Project.transaction do
        Gitlab::SQL::BulkInsert.new(service_hash.keys + ['project_id'],
                                    service_list,
                                    'services').execute
        run_callbacks(batch)
      end
    end

    def project_ids_batch
      Project.connection.select_values(
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
      )
    end

    def service_hash
      @service_hash ||=
        begin
          template_hash = @template.as_json(methods: :type).except('id', 'template', 'project_id')

          template_hash.each_with_object({}) do |(key, value), service_hash|
            value = value.is_a?(Hash) ? value.to_json : value
            key = Gitlab::Database.postgresql? ? "\"#{key}\"" : "`#{key}`"

            service_hash[key] = ActiveRecord::Base.sanitize(value)
          end
        end
    end

    def run_callbacks(batch)
      if active_external_issue_tracker?
        Project.where(id: batch).update_all(has_external_issue_tracker: true)
      end

      if active_external_wiki?
        Project.where(id: batch).update_all(has_external_wiki: true)
      end
    end

    def active_external_issue_tracker?
      @template['category'] == 'issue_tracker' && @template['active'] && !@template['default']
    end

    def active_external_wiki?
      @template['type'] == 'ExternalWikiService' && @template['active']
    end
  end
end
