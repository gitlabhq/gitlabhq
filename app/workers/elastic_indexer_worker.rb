class ElasticIndexerWorker
  include Sidekiq::Worker
  include Elasticsearch::Model::Client::ClassMethods

  sidekiq_options queue: :elasticsearch, retry: 2

  ISSUE_TRACKED_FIELDS = %w(assignee_id author_id confidential)

  def perform(operation, class_name, record_id, options = {})
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

      clear_project_indexes(record_id) if klass == Project
    end
  rescue Elasticsearch::Transport::Transport::Errors::NotFound, ActiveRecord::RecordNotFound
    true # Less work to do!
  end

  private

  def update_issue_notes(record, changed_fields)
    if changed_fields && (changed_fields & ISSUE_TRACKED_FIELDS).any?
      Note.import_with_parent query: -> { where(noteable: record) }
    end
  end

  def clear_project_indexes(record_id)
    remove_repository_index(record_id)
    remove_wiki_index(record_id)
    remove_nested_content(record_id)
  end

  def remove_repository_index(record_id)
    client.delete_by_query({
      index: Repository.__elasticsearch__.index_name,
      body: {
        query: {
          or: [
            { term: { "commit.rid" => record_id } },
            { term: { "blob.rid" => record_id } }
          ]
        }
      }
    })
  end

  def remove_nested_content(record_id)
    client.delete_by_query({
      index: Project.__elasticsearch__.index_name,
      body: {
        query: {
          term: { "_parent" => record_id }
        }
      }
    })
  end

  def remove_wiki_index(record_id)
    client.delete_by_query({
      index: ProjectWiki.__elasticsearch__.index_name,
      body: {
        query: {
          term: { "blob.rid" => "wiki_#{record_id}" }
        }
      }
    })
  end
end
