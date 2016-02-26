class ElasticIndexerWorker
  include Sidekiq::Worker
  
  sidekiq_options queue: :elasticsearch

  Client = Elasticsearch::Client.new(host: Gitlab.config.elasticsearch.host,
                                     port: Gitlab.config.elasticsearch.port)

  def perform(operation, klass, record_id, options = {})
    cklass = klass.constantize

    case operation.to_s
    when /index|update/
      record = cklass.find(record_id)
      record.__elasticsearch__.client = Client
      record.__elasticsearch__.__send__ "#{operation}_document"
    when /delete/
      Client.delete index: cklass.index_name, type: cklass.document_type, id: record_id
    end
  end
end
