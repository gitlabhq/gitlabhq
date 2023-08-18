# frozen_string_literal: true

module Tasks
  module Gitlab
    module AuditEventTypes
      class CheckDocsTask
        def initialize(docs_dir, docs_path, template_erb_path)
          @event_types_dir = docs_dir
          @audit_event_types_doc_file = docs_path
          @event_type_erb_template = ERB.new(File.read(template_erb_path), trim_mode: '<>')
        end

        def run
          doc = File.read(@audit_event_types_doc_file)

          if doc == @event_type_erb_template.result
            puts "Audit event types documentation is up to date."
          else
            error_message = "Audit event types documentation is outdated! Please update it by running " \
                            "`bundle exec rake gitlab:audit_event_types:compile_docs`."
            heading = '#' * 10
            puts heading
            puts '#'
            puts "# #{error_message}"
            puts '#'
            puts heading

            abort
          end
        end
      end
    end
  end
end
