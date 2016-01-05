module ApplicationSearch
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model

    # $ host git-elasticsearch-1.production.infra.home
    # git-elasticsearch-1.production.infra.home has address 10.40.56.23
    self.__elasticsearch__.client = Elasticsearch::Client.new host: Gitlab.config.elasticsearch.host, port: Gitlab.config.elasticsearch.port

    index_name [Rails.application.class.parent_name.downcase, self.name.downcase, Rails.env].join('-')

    settings \
      index: {
      query: {
        default_field: :name
      },
      analysis: {
        :analyzer => {
          :index_analyzer => {
            type: "custom",
            tokenizer: "ngram_tokenizer",
            filter: %w(lowercase asciifolding name_ngrams)
          },
          :search_analyzer => {
            type: "custom",
            tokenizer: "standard",
            filter: %w(lowercase asciifolding )
          }
        },
        tokenizer: {
          ngram_tokenizer: {
            type: "NGram",
            min_gram: 1,
            max_gram: 20,
            token_chars: %w(letter digit connector_punctuation punctuation)
          }
        },
        filter: {
          name_ngrams: {
            type:     "NGram",
            max_gram: 20,
            min_gram: 1
          }
        }
      }
    }

    after_commit lambda { Resque.enqueue(Elastic::BaseIndexer, :index,  self.class.to_s, self.id) }, on: :create
    after_commit lambda { Resque.enqueue(Elastic::BaseIndexer, :update, self.class.to_s, self.id) }, on: :update
    after_commit lambda { Resque.enqueue(Elastic::BaseIndexer, :delete, self.class.to_s, self.id) }, on: :destroy
    after_touch  lambda { Resque.enqueue(Elastic::BaseIndexer, :update, self.class.to_s, self.id) }
  end

   module ClassMethods
     def highlight_options(fields)
       es_fields = fields.map { |field| field.split('^').first }.inject({}) do |memo, field|
         memo[field.to_sym] = {}
         memo
       end

       {
           pre_tags: ["gitlabelasticsearch→"],
           post_tags: ["←gitlabelasticsearch"],
           fields: es_fields
       }
     end
   end
end
