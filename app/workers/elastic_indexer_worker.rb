class ElasticIndexerWorker
  include Sidekiq::Worker
  include Elasticsearch::Model::Client::ClassMethods
  include Gitlab::CurrentSettings

  sidekiq_options queue: :elasticsearch, retry: 2

  ISSUE_TRACKED_FIELDS = %w(assignee_id author_id confidential).freeze

  def perform(operation, class_name, record_id, options = {})
    return true unless current_application_settings.elasticsearch_indexing?

    klass = class_name.constantize

    case operation.to_s
    when /index|update/
      record = klass.find(record_id)
      record.__elasticsearch__.client = client

      if klass.nested?
        record.__elasticsearch__.__send__ "#{operation}_document", parent: record.es_parent
      else
        record.__elasticsearch__.__send__ "#{operation}_document"
      end

      update_issue_notes(record, options["changed_fields"]) if klass == Issue
    when /delete/
      if klass.nested?
        client.delete(
          index: klass.index_name,
          type: klass.document_type,
          id: record_id,
          parent: options["project_id"]
        )
      else
        client.delete index: klass.index_name, type: klass.document_type, id: record_id
      end

      clear_project_data(record_id) if klass == Project
    end
  rescue Elasticsearch::Transport::Transport::Errors::NotFound, ActiveRecord::RecordNotFound
    # These errors can happen in several cases, including:
    # - A record is updated, then removed before the update is handled
    # - Indexing is enabled, but not every item has been indexed yet - updating
    #   and deleting the un-indexed records will raise exception
    #
    # We can ignore these.
    true
  end

  private

  def update_issue_notes(record, changed_fields)
    if changed_fields && (changed_fields & ISSUE_TRACKED_FIELDS).any?
      Note.import_with_parent query: -> { where(noteable: record) }
    end
  end

  def clear_project_data(record_id)
    remove_children_documents(Repository.document_type, record_id)
    remove_children_documents(ProjectWiki.document_type, record_id)
    remove_children_documents(MergeRequest.document_type, record_id)
    remove_documents_by_project_id(record_id)
  end

  def remove_documents_by_project_id(record_id)
    client.delete_by_query({
      index: Project.__elasticsearch__.index_name,
      body: {
        query: {
          term: { "project_id" => record_id }
        }
      }
    })
  end

  def remove_children_documents(document_type, parent_record_id)
    client.delete_by_query({
      index: Project.__elasticsearch__.index_name,
      body: {
        query: {
          parent_id: {
            type: document_type,
            id: parent_record_id
          }
        }
      }
    })
  end
end
