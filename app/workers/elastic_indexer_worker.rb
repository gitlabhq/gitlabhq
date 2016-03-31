class ElasticIndexerWorker
  include Sidekiq::Worker

  sidekiq_options queue: :elasticsearch

  Client = Elasticsearch::Client.new(host: Gitlab.config.elasticsearch.host,
                                     port: Gitlab.config.elasticsearch.port)

  def perform(operation, class_name, record_id, options = {})
    klass = class_name.constantize

    case operation.to_s
    when /index|update/
      record = klass.find(record_id)
      record.__elasticsearch__.client = Client
      record.__elasticsearch__.__send__ "#{operation}_document"
    when /delete/
      Client.delete index: klass.index_name, type: klass.document_type, id: record_id

      clear_project_indexes(record_id) if klass == Project
    end
  rescue Elasticsearch::Transport::Transport::Errors::NotFound
    true # Less work to do!
  end

  def clear_project_indexes(record_id)
    # Remove repository index
    Client.delete_by_query({
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

    # Remove wiki index
    Client.delete_by_query({
      index: ProjectWiki.__elasticsearch__.index_name,
      body: {
        query: {
          term: { "blob.rid" => "wiki_#{record_id}" }
        }
      }
    })
  end
end
