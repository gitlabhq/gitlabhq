module ApplicationSearch
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model

    self.__elasticsearch__.client = Elasticsearch::Client.new host: Gitlab.config.elasticsearch.host, port: Gitlab.config.elasticsearch.port

    index_name [Rails.application.class.parent_name.downcase, self.name.downcase, Rails.env].join('-')

    settings \
      index: {
        query: {
          default_field: :name
        },
        analysis: {
          :analyzer => {
            :my_analyzer => {
              type: "custom",
              tokenizer: "ngram_tokenizer",
              filter: %w(lowercase asciifolding name_ngrams)
            },
            :search_analyzer => {
              type: "custom",
              tokenizer: "standard",
              filter: %w(lowercase asciifolding)
            }
          },
          tokenizer: {
            ngram_tokenizer: {
              type: "nGram",
              min_gram: 1,
              max_gram: 20,
              token_chars: %w(letter digit connector_punctuation punctuation)
            }
          },
          filter: {
            name_ngrams: {
              type:     "nGram",
              max_gram: 20,
              min_gram: 1
            }
          }
        }
      }

    after_commit ->{ ElasticIndexerWorker.perform_async(:index, self.class.to_s, self.id) }, on: :create
    after_commit ->{ ElasticIndexerWorker.perform_async(:update, self.class.to_s, self.id) }, on: :update
    after_commit ->{ ElasticIndexerWorker.perform_async(:delete, self.class.to_s, self.id) }, on: :destroy
  end

   module ClassMethods
     def highlight_options(fields)
       es_fields = fields.map { |field| field.split('^').first }.inject({}) do |memo, field|
         memo[field.to_sym] = {}
         memo
       end

       { fields: es_fields }
     end
   end
end
