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

## See also

- [Bullet](profiling.md#Bullet) For finding `N+1` query problems
- [Performance guidelines](performance.md)
- [Merge request performance guidelines](merge_request_performance_guidelines.md#query-counts)