# frozen_string_literal: true

require_relative 'docs_helper'

# This proc is assigned to a top-level constant so that its lexical nesting is
# empty, ensuring constants like Gitlab::Audit::Type::Definition resolve
# correctly when the captured binding is used inside ERB templates.
AUDIT_EVENT_TYPES_BINDING_FACTORY = proc do |helper_module|
  context = Object.new
  context.extend(helper_module)
  context.instance_eval { binding }
end

module Tasks
  module Gitlab
    module AuditEventTypes
      class CompileDocsTask
        def self.template_binding
          AUDIT_EVENT_TYPES_BINDING_FACTORY.call(Tasks::Gitlab::AuditEventTypes::DocsHelper)
        end

        def initialize(docs_dir, docs_path, template_erb_path)
          @event_types_dir = docs_dir
          @audit_event_types_doc_file = docs_path
          @event_type_erb_template = ERB.new(File.read(template_erb_path), trim_mode: '<>')
        end

        def run
          FileUtils.mkdir_p(@event_types_dir)
          File.write(@audit_event_types_doc_file, @event_type_erb_template.result(self.class.template_binding))

          puts "Documentation compiled."
        end
      end
    end
  end
end
