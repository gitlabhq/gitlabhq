# frozen_string_literal: true

require 'marginalia'

::Marginalia::Comment.extend(::Gitlab::Marginalia::Comment)

# Patch to modify 'Marginalia::ActiveRecordInstrumentation.annotate_sql' method with feature check.
# Orignal Marginalia::ActiveRecordInstrumentation is included to ActiveRecord::ConnectionAdapters::PostgreSQLAdapter in the Marginalia Railtie.
# Refer: https://github.com/basecamp/marginalia/blob/v1.8.0/lib/marginalia/railtie.rb#L67
ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(Gitlab::Marginalia::ActiveRecordInstrumentation)

Marginalia::Comment.components = [:application, :controller, :action, :correlation_id, :jid, :job_class, :line]

Gitlab::Marginalia.set_application_name

Gitlab::Marginalia.enable_sidekiq_instrumentation

Gitlab::Marginalia.set_feature_cache
