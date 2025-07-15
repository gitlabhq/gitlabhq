---
stage: Data Access
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Metrics for measuring monorepo performance
---

To measure server-side performance of your monorepo, use these metrics. While they are general metrics
to measure the performance of Gitaly, they are especially relevant to large repositories.

Clones and fetches are the most frequent expensive operations. When taken as a percentage of system resources
consumed, these operations often contribute to 90% or more of system resources on Gitaly nodes.
Your logs and metrics provide clues to the health of your repository.

## CPU and memory

Two main RPCs (remote procedure calls) handle clones and fetches. Use these fields in your Gitaly
logs to inspect how much repository clones and fetches are consuming system resources.
Filter your Gitaly logs by any of these fields to learn more:

| Log field                         | Values to filter on                                                                          | Description |
|:----------------------------------|:---------------------------------------------------------------------------------------------|:------------|
| `json.grpc.method`                | `PostReceivePack`                                                                            | The RPC that handles HTTP clones and fetches. |
| `json.grpc.method`                | `SSHReceivePack`                                                                             | The RPC that handles SSH clones and fetches. |
| `json.grpc.code`                  | `OK`                                                                                         | Whether the RPC served its request successfully. |
| `json.grpc.code`                  | `Canceled`                                                                                   | Can show if the client killed the connection. Often due to a timeout. |
| `json.grpc.code`                  | `ResourceExhausted`                                                                          | Indicates if the machine is spawning too many Git processes simultaneously. |
| `json.user_id`                    | The `user_id` initiating the clone or fetch, in the form `user-<user_id>`, like `user-22345` | Find excessive clone or fetch operations spawned by a single user. |
| `json.username`                   | The username who initiated the clone or fetch.                                               | Find excessive clone or fetch operations spawned by a single user. |
| `json.grpc.request.glRepository`  | A repository, in the form of `project-<project_id>`, like `project-214`                      | Find the total clones and fetches for a single repository. |
| `json.grpc.request.glProjectPath` | A repository, in the form of a project path, like `my-org/coolproject`                       | Find the total clones and fetches for a given repository. |

These log entry fields give information about CPU and memory:

| Log field to inspect       | Description |
|:---------------------------|:------------|
| `json.command.cpu_time_ms` | CPU time used by subprocesses spawned from this RPC. |
| `json.command.maxrss`      | Memory consumption from subprocesses spawned from this RPC. |

In this example, log message `json.command.cpu_time_ms` was `420`, and `json.command.maxrss` was `3342152`:

```json
{
    "command.count":2,
    "command.cpu_time_ms":420,
    "command.inblock":0,
    "command.majflt":0,
    "command.maxrss":3342152,
    "command.minflt":24316,
    "command.oublock":56,
    "command.real_time_ms":626,
    "command.spawn_token_fork_ms":4,
    "command.spawn_token_wait_ms":0,
    "command.system_time_ms":172,
    "command.user_time_ms":248,
    "component":"gitaly.StreamServerInterceptor",
    "correlation_id":"20HCB3DAEPLV08UGNIYT9HJ4JW",
    "environment":"gprd",
    "feature_flags":"",
    "fqdn":"file-99-stor-gprd.c.gitlab-production.internal",
    "grpc.code":"OK",
    "grpc.meta.auth_version":"v2",
    "grpc.meta.client_name":"gitlab-workhorse",
    "grpc.meta.deadline_type":"none",
    "grpc.meta.method_operation":"mutator",
    "grpc.meta.method_scope":"repository",
    "grpc.meta.method_type":"bidi_stream",
    "grpc.method":"PostReceivePack",
    "grpc.request.fullMethod":"/gitaly.SmartHTTPService/PostReceivePack",
    "grpc.request.glProjectPath":"r2414/revenir/development/machinelearning/protein-ddg",
    "grpc.request.glRepository":"project-47506374",
    "grpc.request.payload_bytes":911,
    "grpc.request.repoPath":"@hashed/db/ab/dbabf83f57affedc9a001dc6c6f6b47bb431bd47d7254edd1daf24f0c38793a9.git",
    "grpc.request.repoStorage":"nfs-file99",
    "grpc.response.payload_bytes":54,
    "grpc.service":"gitaly.SmartHTTPService",
    "grpc.start_time":"2023-10-16T20:40:08.836",
    "grpc.time_ms":631.486,
    "hostname":"file-99-stor-gprd",
    "level":"info",
    "msg":"finished streaming call with code OK",
    "pid":1741362,
    "remote_ip":"108.163.136.48",
    "shard":"default",
    "span.kind":"server",
    "stage":"main",
    "system":"grpc",
    "tag":"gitaly",
    "tier":"stor",
    "time":"2023-10-16T20:40:09.467Z",
    "trace.traceid":"AAB3QAeD8G+H9VNmzOi2CztMAcJv1+g4+l1cAgA=",
    "type":"gitaly",
    "user_id":"user-14857500",
    "username":"ctx_ckottke",
  }
```

## Read distribution

To check the number of reads to each Gitaly node, check `gitaly_praefect_read_distribution`.
This Prometheus metric is a [counter](https://prometheus.io/docs/concepts/metric_types/#counter),
and has two vectors:

| Metric name                         | Vector            | Description |
|-------------------------------------|-------------------|-------------|
| `gitaly_praefect_read_distribution` | `virtual_storage` | The [virtual storage](../../../../administration/gitaly/praefect/_index.md) name. |
| `gitaly_praefect_read_distribution` | `storage`         | The Gitaly storage name. |

## Pack objects cache

To check the [pack objects cache](../../../../administration/gitaly/configure_gitaly.md#pack-objects-cache),
check your logs and your Prometheus metrics:

| Log field name                        | Description |
|:--------------------------------------|:------------|
| `pack_objects_cache.hit`              | Whether the current pack-objects cache was hit. (`true` or `false`) |
| `pack_objects_cache.key`              | Cache key used for the pack-objects cache. |
| `pack_objects_cache.generated_bytes`  | Size in bytes of the new cache being written. |
| `pack_objects_cache.served_bytes`     | Size in bytes of the cache being served. |
| `pack_objects.compression_statistics` | Statistics for pack-objects generation. |
| `pack_objects.enumerate_objects_ms`   | Total time, in ms, spent enumerating objects sent by clients. |
| `pack_objects.prepare_pack_ms`        | Total time, in ms, spent preparing the packfile before sending it back to the client |
| `pack_objects.write_pack_file_ms`     | Total time, in ms, spent sending the packfile back to the client. Highly dependent on the client's internet connection. |
| `pack_objects.written_object_count`   | Total number of objects Gitaly sent back to the client. |

Example log message:

```json
{
"bytes":26186490,
"correlation_id":"01F1MY8JXC3FZN14JBG1H42G9F",
"grpc.meta.deadline_type":"none",
"grpc.method":"PackObjectsHook",
"grpc.request.fullMethod":"/gitaly.HookService/PackObjectsHook",
"grpc.request.glProjectPath":"root/gitlab-workhorse",
"grpc.request.glRepository":"project-2",
"grpc.request.repoPath":"@hashed/d4/73/d4735e3a265e16eee03f59718b9b5d03019c07d8b6c51f90da3a666eec13ab35.git",
"grpc.request.repoStorage":"default",
"grpc.request.topLevelGroup":"@hashed",
"grpc.service":"gitaly.HookService",
"grpc.start_time":"2021-03-25T14:57:52.747Z",
"level":"info",
"msg":"finished unary call with code OK",
"peer.address":"@",
"pid":20961,
"span.kind":"server",
"system":"grpc",
"time":"2021-03-25T14:57:53.543Z",
"pack_objects.compression_statistics": "Total 145991 (delta 68), reused 6 (delta 2), pack-reused 145911",
"pack_objects.enumerate_objects_ms": 170,
"pack_objects.prepare_pack_ms": 7,
"pack_objects.write_pack_file_ms": 786,
"pack_objects.written_object_count": 145991,
"pack_objects_cache.generated_bytes": 49533030,
"pack_objects_cache.hit": "false",
"pack_objects_cache.key": "123456789",
"pack_objects_cache.served_bytes": 49533030,
"peer.address": "127.0.0.1",
"pid": 8813,
}
```

| Prometheus metric name                    | Vector   | Description |
|:------------------------------------------|:---------|:------------|
| `gitaly_pack_objects_served_bytes_total`  |          | Size (in bytes) of the cache being served. |
| `gitaly_pack_objects_cache_lookups_total` | `result` | Whether a cache lookup resulted in a `hit` or `miss`. |
