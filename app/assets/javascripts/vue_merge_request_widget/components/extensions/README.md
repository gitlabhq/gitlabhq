### Widget Extensions

#### Telemetry

Telemetry is enabled by default in all widget extensions.

However, telemetry events are not reported until they have been marked as a "known event" with a Metric Dictionary.

If telemetry metrics are desired when adding a widget extension, it is important to also create known events.

The following steps are needed to generate these known events for a single widget:

1. Widgets should be named `Widget${CamelName}`.
    - For example: a widget for "Test Reports" should be `WidgetTestReports`
1. "Compute" the widget name slug by converting the `${CamelName}` to lower-, snake-case.
    - The above example would be `test_reports`
1. Add the new widget name slug to `lib/gitlab/usage_data_counters/merge_request_widget_extension_counter.rb` in the `WIDGETS` list.
1. Ensure the GDK is running (`gdk start`)
1. Generate known events on the command line with the following command. Replace `test_reports` with your appropriate name slug.
    ```
    bundle exec rails generate gitlab:usage_metric_definition \
    counts.code_review.i_merge_request_widget_test_reports_count_view \
    counts.code_review.i_merge_request_widget_test_reports_count_full_report_clicked \
    counts.code_review.i_merge_request_widget_test_reports_count_expand \
    counts.code_review.i_merge_request_widget_test_reports_count_expand_success \
    counts.code_review.i_merge_request_widget_test_reports_count_expand_warning \
    counts.code_review.i_merge_request_widget_test_reports_count_expand_failed \
    --dir=all
    ```
1. Modify each newly generated file so that they match the existing files for MR Widget Extension telemetry.
    - You can find existing examples by doing a glob search like so: `metrics/**/*_i_code_review_merge_request_widget_*`
    - Roughly-speaking, each file should have these values:
        1. `description` = A plain English description of this value. Please see existing widget extension telemetry files for examples.
        1. `product_section` = `dev`
        1. `product_stage` = `create`
        1. `product_group` = `code_review`
        1. `product_category` = `code_review`
        1. `introduced_by_url` = `'[your MR]'`
        1. `options.events` = (the event in the command from above that generated this file, like `i_code_review_merge_request_widget_test_reports_count_view`)
            - This is how the telemetry events are linked to "metrics" so this is probably one of the more important values
        1. `data_source` = `redis`
        1. `data_category` = `optional`
1. Repeat steps 5 and 6 for the HLL metrics. Replace `test_reports` with your appropriate name slug.
    ```
    bundle exec rails generate gitlab:usage_metric_definition:redis_hll code_review \
    i_code_review_merge_request_widget_test_reports_view \
    i_code_review_merge_request_widget_test_reports_full_report_clicked \
    i_code_review_merge_request_widget_test_reports_expand \
    i_code_review_merge_request_widget_test_reports_expand_success \
    i_code_review_merge_request_widget_test_reports_expand_warning \
    i_code_review_merge_request_widget_test_reports_expand_failed \
    --class_name=RedisHLLMetric
    ```
    - In step 6 for HLL, change the `data_source` to `redis_hll`.
1. Add each of the HLL metrics to `lib/gitlab/usage_data_counters/known_events/code_review_events.yml`
    1. `name` = [the event]
    1. `redis_slot` = `code_review`
    1. `category` = `code_review`
    1. `aggregation` = `weekly`
1. Add each event to the appropriate aggregates in `config/metrics/aggregates/code_review.yml`

##### New Events

If you are adding a new event to our known events, it will need to be included in `lib/gitlab/usage_data_counters/merge_request_widget_extension_counter.rb`. Update the list of `KNOWN_EVENTS` with the new event(s).
