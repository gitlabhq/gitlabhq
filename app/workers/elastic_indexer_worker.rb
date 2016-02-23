class ElasticIndexerWorker
  include Sidekiq::Worker
  
  sidekiq_options queue: :elasticsearch

  Client = Elasticsearch::Client.new(host: Gitlab.config.elasticsearch.host,
                                     port: Gitlab.config.elasticsearch.port)

  def perform(operation, klass, record_id, options = {})
    klass = "Snippet" if klass =~ /Snippet$/

    cklass = klass.constantize

    case operation.to_s
    when /index|update/
      record = cklass.find(record_id)
      record.__elasticsearch__.client = Client
      record.__elasticsearch__.__send__ "#{operation}_document"
    when /delete/
      Client.delete index: cklass.index_name, type: cklass.document_type, id: record_id

      if cklass == Project
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
  end
end
