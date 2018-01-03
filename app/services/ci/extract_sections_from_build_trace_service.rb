module Ci
  class ExtractSectionsFromBuildTraceService < BaseService
    def execute(build)
      return false unless build.trace_sections.empty?

      Gitlab::Database.bulk_insert(BuildTraceSection.table_name, extract_sections(build))
      true
    end

    private

    def find_or_create_name(name)
      project.build_trace_section_names.find_or_create_by!(name: name)
    rescue ActiveRecord::RecordInvalid
      project.build_trace_section_names.find_by!(name: name)
    end

    def extract_sections(build)
      build.trace.extract_sections.map do |attr|
        name = attr.delete(:name)
        name_record = find_or_create_name(name)

        attr.merge(
          build_id: build.id,
          project_id: project.id,
          section_name_id: name_record.id)
      end
    end
  end
end
