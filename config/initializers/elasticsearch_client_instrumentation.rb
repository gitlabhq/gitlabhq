# frozen_string_literal: true

::Elasticsearch::Transport::Client.prepend ::Gitlab::Instrumentation::ElasticsearchTransport::Interceptor
