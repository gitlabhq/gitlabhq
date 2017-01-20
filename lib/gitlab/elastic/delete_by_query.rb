module Elasticsearch
  module API
    module Actions
      # The built-in action https://github.com/elastic/elasticsearch-ruby/blob/master/elasticsearch-api/lib/elasticsearch/api/actions/delete_by_query.rb
      # does not work with Elasticsearch 5.0 yet. There is an issue for that https://github.com/elastic/elasticsearch-ruby/issues/387
      # but until it's not fixed we can use our own action for that
      def gitlab_delete_by_query(arguments = {})
        raise ArgumentError, "Required argument 'index' missing" unless arguments[:index]

        valid_params = [
          :analyzer,
          :consistency,
          :default_operator,
          :df,
          :ignore_indices,
          :ignore_unavailable,
          :allow_no_indices,
          :expand_wildcards,
          :replication,
          :q,
          :routing,
          :source,
          :timeout ]

        method = HTTP_POST
        path   = Utils.__pathify Utils.__listify(arguments[:index]),
                                 Utils.__listify(arguments[:type]),
                                 '/_delete_by_query'

        params = Utils.__validate_and_extract_params arguments, valid_params
        body   = arguments[:body]

        perform_request(method, path, params, body).body
      end
    end
  end
end
