# InfluxDB Schema

The following measurements are currently stored in InfluxDB:

- `PROCESS_file_descriptors`
- `PROCESS_gc_statistics`
- `PROCESS_memory_usage`
- `PROCESS_method_calls`
- `PROCESS_object_counts`
- `PROCESS_transactions`
- `PROCESS_views`

Here, `PROCESS` is replaced with either `rails` or `sidekiq` depending on the
process type. In all series, any form of duration is stored in milliseconds.

## PROCESS_file_descriptors

This measurement contains the number of open file descriptors over time. The
value field `value` contains the number of descriptors.

## PROCESS_gc_statistics

This measurement contains Ruby garbage collection statistics such as the amount
of minor/major GC runs (relative to the last sampling interval), the time spent
in garbage collection cycles, and all fields/values returned by `GC.stat`.

## PROCESS_memory_usage

This measurement contains the process' memory usage (in bytes) over time. The
value field `value` contains the number of bytes.

## PROCESS_method_calls

This measurement contains the methods called during a transaction along with
their duration, and a name of the transaction action that invoked the method (if
available). The method call duration is stored in the value field `duration`,
while the method name is stored in the tag `method`. The tag `action` contains
the full name of the transaction action. Both the `method` and `action` fields
are in the following format:

```
ClassName#method_name
```

For example, a method called by the `show` method in the `UsersController` class
would have `action` set to `UsersController#show`.

## PROCESS_object_counts

This measurement is used to store retained Ruby objects (per class) and the
amount of retained objects. The number of objects is stored in the `count` value
field while the class name is stored in the `type` tag.

## PROCESS_transactions

This measurement is used to store basic transaction details such as the time it
took to complete a transaction, how much time was spent in SQL queries, etc. The
following value fields are available:

| Value | Description |
| ----- | ----------- |
| `duration`  | The total duration of the transaction |
| `allocated_memory` | The amount of bytes allocated while the transaction was running. This value is only reliable when using single-threaded application servers |
| `method_duration` | The total time spent in method calls |
| `sql_duration` | The total time spent in SQL queries |
| `view_duration` | The total time spent in views |

## PROCESS_views

This measurement is used to store view rendering timings for a transaction. The
following value fields are available:

| Value | Description |
| ----- | ----------- |
| `duration` | The rendering time of the view |
| `view` | The path of the view, relative to the application's root directory |

The `action` tag contains the action name of the transaction that rendered the
view.

---

Read more on:

- [Introduction to GitLab Performance Monitoring](introduction.md)
- [GitLab Configuration](gitlab_configuration.md)
- [InfluxDB Configuration](influxdb_configuration.md)
- [Grafana Install/Configuration](grafana_configuration.md
