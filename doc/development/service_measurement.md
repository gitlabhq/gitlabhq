---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: GitLab Developers Guide to service measurement
---

You can enable service measurement to debug any slow service's execution time, number of SQL calls, garbage collection stats, memory usage, etc.

## Measuring module

The measuring module is a tool that allows to measure a service's execution, and log:

- Service class name
- Execution time
- Number of SQL calls
- Detailed `gc` stats and diffs
- RSS memory usage
- Server worker ID

The measuring module logs these measurements into a structured log called [`service_measurement.log`](../administration/logs/_index.md#service_measurementlog),
as a single entry for each service execution.

For GitLab.com, `service_measurement.log` is ingested in Elasticsearch and Kibana as part of our monitoring solution.

## How to use it

The measuring module allows you to easily measure and log execution of any service,
by just prepending `Measurable` in any Service class, on the last line of the file that the class resides in.

For example, to prepend a module into the `DummyService` class, you would use the following approach:

```ruby
class DummyService
  def execute
  # ...
  end
end

DummyService.prepend(Measurable)
```

In case when you are prepending a module from the `EE` namespace with EE features, you need to prepend Measurable after prepending the `EE` module.

This way, `Measurable` is at the bottom of the ancestor chain, to measure execution of `EE` features as well:

```ruby
class DummyService
  def execute
  # ...
  end
end

DummyService.prepend_mod_with('DummyService')
DummyService.prepend(Measurable)
```

### Log additional attributes

In case you need to log some additional attributes, it is possible to define `extra_attributes_for_measurement` in the service class:

```ruby
def extra_attributes_for_measurement
  {
    project_path: @project.full_path,
    user: current_user.name
  }
end
```

After the measurement module is injected in the service, it is behind a generic feature flag.
To actually use it, you need to enable measuring for the desired service by enabling the feature flag.

### Enabling measurement using feature flags

In the following example, the `:gitlab_service_measuring_projects_import_service`
[feature flag](feature_flags/_index.md#controlling-feature-flags-locally) is used to enable the measuring feature
for `Projects::ImportService`.

From ChatOps:

```shell
/chatops run feature set gitlab_service_measuring_projects_import_service true
```
