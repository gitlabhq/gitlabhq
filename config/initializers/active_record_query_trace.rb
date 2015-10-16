if ENV['ENABLE_QUERY_TRACE']
  require 'active_record_query_trace'

  ActiveRecordQueryTrace.enabled = 'true'
end
