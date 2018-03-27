# QueryRecorder

QueryRecorder is a tool for detecting the [N+1 queries problem](http://guides.rubyonrails.org/active_record_querying.html#eager-loading-associations) from tests.

> Implemented in [spec/support/query_recorder.rb](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/spec/support/query_recorder.rb) via [9c623e3e](https://gitlab.com/gitlab-org/gitlab-ce/commit/9c623e3e5d7434f2e30f7c389d13e5af4ede770a)

As a rule, merge requests [should not increase query counts](merge_request_performance_guidelines.md#query-counts). If you find yourself adding something like `.includes(:author, :assignee)` to avoid having `N+1` queries, consider using QueryRecorder to enforce this with a test. Without this, a new feature which causes an additional model to be accessed will silently reintroduce the problem.

## How it works

This style of test works by counting the number of SQL queries executed by ActiveRecord. First a control count is taken, then you add new records to the database and rerun the count. If the number of queries has significantly increased then an `N+1` queries problem exists.

```ruby
it "avoids N+1 database queries" do
  control_count = ActiveRecord::QueryRecorder.new { visit_some_page }.count
  create_list(:issue, 5)
  expect { visit_some_page }.not_to exceed_query_limit(control_count)
end
```

As an example you might create 5 issues in between counts, which would cause the query count to increase by 5 if an N+1 problem exists.

> **Note:** In some cases the query count might change slightly between runs for unrelated reasons. In this case you might need to test `exceed_query_limit(control_count + acceptable_change)`, but this should be avoided if possible.

## Finding the source of the query

It may be useful to identify the source of the queries by looking at the call backtrace.
To enable this, run the specs with the `QUERY_RECORDER_DEBUG` environment variable set. For example:

```
QUERY_RECORDER_DEBUG=1 bundle exec rspec spec/requests/api/projects_spec.rb
```

This will log calls to QueryRecorder into the `test.log`. For example:

```
QueryRecorder SQL: SELECT COUNT(*) FROM "issues" WHERE "issues"."deleted_at" IS NULL AND "issues"."project_id" = $1 AND ("issues"."state" IN ('opened')) AND "issues"."confidential" = $2
   --> /home/user/gitlab/gdk/gitlab/spec/support/query_recorder.rb:19:in `callback'
   --> /home/user/.rbenv/versions/2.3.5/lib/ruby/gems/2.3.0/gems/activesupport-4.2.8/lib/active_support/notifications/fanout.rb:127:in `finish'
   --> /home/user/.rbenv/versions/2.3.5/lib/ruby/gems/2.3.0/gems/activesupport-4.2.8/lib/active_support/notifications/fanout.rb:46:in `block in finish'
   --> /home/user/.rbenv/versions/2.3.5/lib/ruby/gems/2.3.0/gems/activesupport-4.2.8/lib/active_support/notifications/fanout.rb:46:in `each'
   --> /home/user/.rbenv/versions/2.3.5/lib/ruby/gems/2.3.0/gems/activesupport-4.2.8/lib/active_support/notifications/fanout.rb:46:in `finish'
   --> /home/user/.rbenv/versions/2.3.5/lib/ruby/gems/2.3.0/gems/activesupport-4.2.8/lib/active_support/notifications/instrumenter.rb:36:in `finish'
   --> /home/user/.rbenv/versions/2.3.5/lib/ruby/gems/2.3.0/gems/activesupport-4.2.8/lib/active_support/notifications/instrumenter.rb:25:in `instrument'
   --> /home/user/.rbenv/versions/2.3.5/lib/ruby/gems/2.3.0/gems/activerecord-4.2.8/lib/active_record/connection_adapters/abstract_adapter.rb:478:in `log'
   --> /home/user/.rbenv/versions/2.3.5/lib/ruby/gems/2.3.0/gems/activerecord-4.2.8/lib/active_record/connection_adapters/postgresql_adapter.rb:601:in `exec_cache'
   --> /home/user/.rbenv/versions/2.3.5/lib/ruby/gems/2.3.0/gems/activerecord-4.2.8/lib/active_record/connection_adapters/postgresql_adapter.rb:585:in `execute_and_clear'
   --> /home/user/.rbenv/versions/2.3.5/lib/ruby/gems/2.3.0/gems/activerecord-4.2.8/lib/active_record/connection_adapters/postgresql/database_statements.rb:160:in `exec_query'
   --> /home/user/.rbenv/versions/2.3.5/lib/ruby/gems/2.3.0/gems/activerecord-4.2.8/lib/active_record/connection_adapters/abstract/database_statements.rb:356:in `select'
   --> /home/user/.rbenv/versions/2.3.5/lib/ruby/gems/2.3.0/gems/activerecord-4.2.8/lib/active_record/connection_adapters/abstract/database_statements.rb:32:in `select_all'
   --> /home/user/.rbenv/versions/2.3.5/lib/ruby/gems/2.3.0/gems/activerecord-4.2.8/lib/active_record/connection_adapters/abstract/query_cache.rb:68:in `block in select_all'
   --> /home/user/.rbenv/versions/2.3.5/lib/ruby/gems/2.3.0/gems/activerecord-4.2.8/lib/active_record/connection_adapters/abstract/query_cache.rb:83:in `cache_sql'
   --> /home/user/.rbenv/versions/2.3.5/lib/ruby/gems/2.3.0/gems/activerecord-4.2.8/lib/active_record/connection_adapters/abstract/query_cache.rb:68:in `select_all'
   --> /home/user/.rbenv/versions/2.3.5/lib/ruby/gems/2.3.0/gems/activerecord-4.2.8/lib/active_record/relation/calculations.rb:270:in `execute_simple_calculation'
   --> /home/user/.rbenv/versions/2.3.5/lib/ruby/gems/2.3.0/gems/activerecord-4.2.8/lib/active_record/relation/calculations.rb:227:in `perform_calculation'
   --> /home/user/.rbenv/versions/2.3.5/lib/ruby/gems/2.3.0/gems/activerecord-4.2.8/lib/active_record/relation/calculations.rb:133:in `calculate'
   --> /home/user/.rbenv/versions/2.3.5/lib/ruby/gems/2.3.0/gems/activerecord-4.2.8/lib/active_record/relation/calculations.rb:48:in `count'
   --> /home/user/gitlab/gdk/gitlab/app/services/base_count_service.rb:20:in `uncached_count'
   --> /home/user/gitlab/gdk/gitlab/app/services/base_count_service.rb:12:in `block in count'
   --> /home/user/.rbenv/versions/2.3.5/lib/ruby/gems/2.3.0/gems/activesupport-4.2.8/lib/active_support/cache.rb:299:in `block in fetch'
   --> /home/user/.rbenv/versions/2.3.5/lib/ruby/gems/2.3.0/gems/activesupport-4.2.8/lib/active_support/cache.rb:585:in `block in save_block_result_to_cache'
   --> /home/user/.rbenv/versions/2.3.5/lib/ruby/gems/2.3.0/gems/activesupport-4.2.8/lib/active_support/cache.rb:547:in `block in instrument'
   --> /home/user/.rbenv/versions/2.3.5/lib/ruby/gems/2.3.0/gems/activesupport-4.2.8/lib/active_support/notifications.rb:166:in `instrument'
   --> /home/user/.rbenv/versions/2.3.5/lib/ruby/gems/2.3.0/gems/activesupport-4.2.8/lib/active_support/cache.rb:547:in `instrument'
   --> /home/user/.rbenv/versions/2.3.5/lib/ruby/gems/2.3.0/gems/activesupport-4.2.8/lib/active_support/cache.rb:584:in `save_block_result_to_cache'
   --> /home/user/.rbenv/versions/2.3.5/lib/ruby/gems/2.3.0/gems/activesupport-4.2.8/lib/active_support/cache.rb:299:in `fetch'
   --> /home/user/gitlab/gdk/gitlab/app/services/base_count_service.rb:12:in `count'
   --> /home/user/gitlab/gdk/gitlab/app/models/project.rb:1296:in `open_issues_count'
```

## See also

- [Bullet](profiling.md#Bullet) For finding `N+1` query problems
- [Performance guidelines](performance.md)
- [Merge request performance guidelines](merge_request_performance_guidelines.md#query-counts)