# frozen_string_literal: true

return if Rails.env.production?

namespace :gitlab do
  namespace :audit_event_types do
    event_types_dir = Rails.root.join("doc/user/compliance")
    event_types_doc_file = Rails.root.join(event_types_dir, 'audit_event_types.md')
    template_directory = 'tooling/audit_events/docs/templates/'
    template_erb_file_path = Rails.root.join(template_directory, 'audit_event_types.md.erb')

    desc 'GitLab | Audit event types | Generate audit event types docs'
    task compile_docs: :environment do
      require_relative './compile_docs_task'

      Tasks::Gitlab::AuditEventTypes::CompileDocsTask
        .new(event_types_dir, event_types_doc_file, template_erb_file_path).run
    end

    desc 'GitLab | Audit event types | Check if Audit event types docs are up to date'
    task check_docs: :environment do
      require_relative './check_docs_task'

      Tasks::Gitlab::AuditEventTypes::CheckDocsTask
        .new(event_types_dir, event_types_doc_file, template_erb_file_path).run
    end
  end
end
