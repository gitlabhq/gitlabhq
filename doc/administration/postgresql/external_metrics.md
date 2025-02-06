---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Monitoring and logging setup for external databases
---

External PostgreSQL database systems have different logging options for monitoring performance and troubleshooting, however they are not enabled by default. In this section we provide the recommendations for self-managed PostgreSQL, and recommendations for some major providers of PostgreSQL managed services.

## Recommended PostgreSQL Logging settings

You should enable the following logging settings:

- `log_statement=ddl`: log changes of database model definition (DDL), such as `CREATE`, `ALTER` or `DROP` of objects. This helps track recent model changes that could be causing performance issues and identify security breaches and human errors.
- `log_lock_waits=on`: log of processes holding [locks](https://www.postgresql.org/docs/current/explicit-locking.html) for long periods, a common cause of poor query performance.
- `log_temp_files=0`: log usage of intense and unusual temporary files that can indicate poor query performance.
- `log_autovacuum_min_duration=0`: log all autovacuum executions. Autovacuum is a key component for overall PostgreSQL engine performance. Essential for troubleshooting and tuning if dead tuples are not being removed from tables.
- `log_min_duration_statement=1000`: log slow queries (slower than 1 second).

The full description of the above parameter settings can be found in
[PostgreSQL error reporting and logging documentation](https://www.postgresql.org/docs/current/runtime-config-logging.html#RUNTIME-CONFIG-LOGGING-WHAT).

## Amazon RDS

The Amazon Relational Database Service (RDS) provides a large number of [monitoring metrics](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Monitoring.html) and [logging interfaces](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Monitor_Logs_Events.html). Here are a few you should configure:

- Change all above [recommended PostgreSQL Logging settings](#recommended-postgresql-logging-settings) through [RDS Parameter Groups](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_WorkingWithDBInstanceParamGroups.html).
  - As the recommended logging parameters are [dynamic in RDS](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.PostgreSQL.CommonDBATasks.Parameters.html) you don't require a reboot after changing these settings.
  - The PostgreSQL logs can be observed through the [RDS console](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/logs-events-streams-console.html).
- Enable [RDS performance insight](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_PerfInsights.html) allows you to visualise your database load with many important performance metrics of a PostgreSQL database engine.
- Enable [RDS Enhanced Monitoring](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_Monitoring.OS.html) to monitor the operating system metrics. These metrics can indicate bottlenecks in your underlying hardware and OS that are impacting your database performance.
  - In production environments set the monitoring interval to 10 seconds (or less) to capture micro bursts of resource usage that can be the cause of many performance issues. Set `Granularity=10` in the console or `monitoring-interval=10` in the CLI.
