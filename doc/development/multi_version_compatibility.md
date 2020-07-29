# Compatibility with multiple versions of the application running at the same time

When adding or changing features, we must be aware that there may be multiple versions of the application running
at the same time and connected to the same PostgreSQL and Redis databases. This could happen during a rolling deploy
when the servers are updated one by one.

During a rolling deploy, post-deployment DB migrations are run after all the servers have been updated. This means the
servers could be in these intermediate states:

1. Old application code running with new DB migrations already executed
1. New application code running with new DB migrations but without new post-deployment DB migrations

We must make sure that the application works properly in these states.

For GitLab.com, we also run a set of canary servers which run a more recent version of the application. Users with
the canary cookie set would be handled by these servers. Some URL patterns may also be forced to the canary servers,
even without the cookie being set. This also means that some pages may match the pattern and get handled by canary servers,
but AJAX requests to URLs (like the GraphQL endpoint) won't match the pattern.

With this canary setup, we'd be in this mixed-versions state for an extended period of time until canary is promoted to
production and post-deployment migrations run.

Also be aware that during a deployment to production, Web, API, and
Sidekiq nodes are updated in parallel, but they may finish at
different times. That means there may be a window of time when the
application code is not in sync across the whole fleet. Changes that
cut across Sidekiq, Web, and/or the API may [introduce unexpected
errors until the deployment is complete](#builds-failing-due-to-varying-deployment-times-across-node-types).

One way to handle this is to use a feature flag that is disabled by
default. The feature flag can be enabled when the deployment is in a
consistent state. However, this method of synchronization doesn't
guarantee that customers with on-premise instances can [upgrade with
zero downtime](https://docs.gitlab.com/omnibus/update/#zero-downtime-updates)
since point releases bundle many changes together. Minimizing the time
between when versions are out of sync across the fleet may help mitigate
errors caused by upgrades.

## Examples of previous incidents

### Some links to issues and MRs were broken

When we moved MR routes, users on the new servers were redirected to the new URLs. When these users shared these new URLs in
Markdown (or anywhere else), they were broken links for users on the old servers.

For more information, see [the relevant issue](https://gitlab.com/gitlab-org/gitlab/-/issues/118840).

### Stale cache in issue or merge request descriptions and comments

We bumped the Markdown cache version and found a bug when a user edited a description or comment which was generated from a different Markdown
cache version. The cached HTML wasn't generated properly after saving. In most cases, this wouldn't have happened because users would have
viewed the Markdown before clicking **Edit** and that would mean the Markdown cache is refreshed. But because we run mixed versions, this is
more likely to happen. Another user on a different version could view the same page and refresh the cache to the other version behind the scenes.

For more information, see [the relevant issue](https://gitlab.com/gitlab-org/gitlab/-/issues/208255).

### Project service templates incorrectly copied

We changed the column which indicates whether a service is a template. When we create services, we copy attributes from the template
and set this column to `false`. The old servers were still updating the old column, but that was fine because we had a DB trigger
that updated the new column from the old one. For the new servers though, they were only updating the new column and that same trigger
was now working against us and setting it back to the wrong value.

For more information, see [the relevant issue](https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/9176).

### Sidebar wasn't loading for some users

We changed the data type of one GraphQL field. When a user opened an issue page from the new servers and the GraphQL AJAX request went
to the old servers, a type mismatch happened, which resulted in a JavaScript error that prevented the sidebar from loading.

For more information, see [the relevant issue](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/1772).

### CI artifact uploads were failing

We added a `NOT NULL` constraint to a column and marked it as a `NOT VALID` constraint so that it is not enforced on existing rows.
But even with that, this was still a problem because the old servers were still inserting new rows with null values.

For more information, see [the relevant issue](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/1944).

### Downtime on release features between canary and production deployment

To address the issue, we added a new column to an existing table with a `NOT NULL` constraint without
specifying a default value. In other words, this requires the application to set a value to the column.

The older version of the application didn't set the `NOT NULL` constraint since the entity/concept didn't
exist before.

The problem starts right after the canary deployment is complete. At that moment,
the database migration (to add the column) has successfully run and canary instance starts using
the new application code, hence QA was successful. Unfortunately, the production
instance still uses the older code, so it started failing to insert a new release entry.

For more information, see [this issue related to the Releases API](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/64151).

### Builds failing due to varying deployment times across node types

In [one production issue](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/2442),
CI builds that used the `parallel` keyword and depending on the
variable `CI_NODE_TOTAL` being an integer failed. This was caused because after a user pushed a commit:

1. New code: Sidekiq created a new pipeline and new build. `build.options[:parallel]` is a `Hash`.
1. Old code: Runners requested a job from an API node that is running the previous version.
1. As a result, the [new code](https://gitlab.com/gitlab-org/gitlab/blob/42b82a9a3ac5a96f9152aad6cbc583c42b9fb082/app/models/concerns/ci/contextable.rb#L104)
was not run on the API server. The runner's request failed because the
older API server tried return the `CI_NODE_TOTAL` CI variable, but
instead of sending an integer value (e.g. 9), it sent a serialized
`Hash` value (`{:number=>9, :total=>9}`).

If you look at the [deployment pipeline](https://ops.gitlab.net/gitlab-com/gl-infra/deployer/-/pipelines/202212),
you see all nodes were updated in parallel:

![GitLab.com deployment pipeline](img/deployment_pipeline_v13_3.png)

However, even though the updated started around the same time, the completion time varied significantly:

|Node type|Duration (min)|
|---------|--------------|
|API      |54            |
|Sidekiq  |21            |
|K8S      |8             |

Builds that used the `parallel` keyword and depended on `CI_NODE_TOTAL`
and `CI_NODE_INDEX` would fail during the time after Sidekiq was
updated. Since Kubernetes (K8S) also runs Sidekiq pods, the window could
have been as long as 46 minutes or as short as 33 minutes. Either way,
having a feature flag to turn on after the deployment finished would
prevent this from happening.
