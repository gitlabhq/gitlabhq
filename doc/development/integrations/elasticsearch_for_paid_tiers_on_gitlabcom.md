# Elasticsearch for paid tiers on GitLab.com

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/220246) in GitLab 13.2
> - It's deployed behind a feature flag, disabled by default.
> - It's disabled on GitLab.com.
> - It's not recommended for use in GitLab self-managed instances.

This document describes how to enable Elasticsearch with GitLab for all paid tiers on GitLab.com. Once enabled,
all paid tiers will have access to the [Advanced Global Search feature](../../integration/elasticsearch.md) on GitLab.com.

## Enable or disable Elasticsearch for all paid tiers on GitLab.com

Since we're still in the process of rolling this out and want to control the timing this is behind a feature flag
which defaults to off.

To enable it:

```ruby
# Instance-wide
Feature.enable(:elasticsearch_index_only_paid_groups)
```

To disable it:

```ruby
# Instance-wide
Feature.disable(:elasticsearch_index_only_paid_groups)
```
