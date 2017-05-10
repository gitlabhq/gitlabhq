module Elasticsearch
  module Git
    module Model
      extend ActiveSupport::Concern

      included do
        extend ActiveModel::Naming
        include ActiveModel::Model
        include Elasticsearch::Model

        env = if defined?(::Rails)
                ::Rails.env.to_s
              else
                nil
              end

        index_name [self.name.downcase, 'index', env].compact.join('-')

        settings \
          index: {
          analysis: {
            analyzer: {
              path_analyzer: {
                type: 'custom',
                tokenizer: 'path_tokenizer',
                filter: %w(lowercase asciifolding)
              },
              sha_analyzer: {
                type: 'custom',
                tokenizer: 'sha_tokenizer',
                filter: %w(lowercase asciifolding)
              },
              code_analyzer: {
                type: 'custom',
                tokenizer: 'standard',
                filter: %w(code lowercase asciifolding),
                char_filter: ["code_mapping"]
              },
              code_search_analyzer: {
                type: 'custom',
                tokenizer: 'standard',
                filter: %w(lowercase asciifolding),
                char_filter: ["code_mapping"]
              }
            },
            tokenizer: {
              sha_tokenizer: {
                type: "edgeNGram",
                min_gram: 5,
                max_gram: 40,
                token_chars: %w(letter digit)
              },
              path_tokenizer: {
                type: 'path_hierarchy',
                reverse: true
              }
            },
            filter: {
              code: {
                type: "pattern_capture",
                preserve_original: 1,
                patterns: [
                  "(\\p{Ll}+|\\p{Lu}\\p{Ll}+|\\p{Lu}+)",
                  "(\\d+)"
                ]
              }
            },
            char_filter: {
              code_mapping: {
                type: "mapping",
                mappings: [
                  ". => ' '"
                ]
              }
            }
          }
        }
      end
    end
  end
end
