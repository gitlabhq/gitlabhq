# frozen_string_literal: true

module Tasks
  module Gitlab
    module AuditEventTypes
      class CompileDocsTask
        def initialize(docs_dir, docs_path, template_erb_path)
          @event_types_dir = docs_dir
          @audit_event_types_doc_file = docs_path
          @event_type_erb_template = ERB.new(File.read(template_erb_path), trim_mode: '<>')
        end

        def run
          FileUtils.mkdir_p(@event_types_dir)
          File.write(@audit_event_types_doc_file, @event_type_erb_template.result)

          puts "Documentation compiled."
        end
      end
    end
  end
end
