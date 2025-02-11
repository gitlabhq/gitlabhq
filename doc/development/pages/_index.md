---
stage: Plan
group: Knowledge
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
description: "GitLab's development guidelines for GitLab Pages"
title: Contribute to GitLab Pages development
---

Learn how to configure GitLab Pages so you can help develop the feature.

## Configuring GitLab Pages hostname

GitLab Pages needs a hostname or domain, as each different GitLab Pages site is accessed through a
subdomain. You can set the GitLab Pages hostname:

- [Without wildcard, editing your hosts file](#without-wildcard-editing-your-hosts-file).
- [With DNS wildcard alternatives](#with-dns-wildcard-alternatives).

### Without wildcard, editing your hosts file

As `/etc/hosts` don't support wildcard hostnames, you must configure one entry
for GitLab Pages, and then one entry for each page site:

```plaintext
127.0.0.1 gdk.test           # If you're using GDK
127.0.0.1 pages.gdk.test     # Pages host
# Any namespace/group/user needs to be added
# as a subdomain to the pages host. This is because
# /etc/hosts doesn't accept wildcards
127.0.0.1 root.pages.gdk.test # for the root pages
```

### With DNS wildcard alternatives

If instead of editing your `/etc/hosts` you'd prefer to use a DNS wildcard, you can use:

- [`nip.io`](https://nip.io)
- [`dnsmasq`](dnsmasq.md)

## Configuring GitLab Pages without GDK

Create a `gitlab-pages.conf` in the root of the GitLab Pages site, like:

```toml
# Default port is 3010, but you can use any other
listen-http=:3010

# Your local GitLab Pages domain
pages-domain=pages.gdk.test

# Directory where the pages are stored
pages-root=shared/pages

# Show more information in the logs
log-verbose=true
```

To see more options you can check
[`internal/config/flags.go`](https://gitlab.com/gitlab-org/gitlab-pages/blob/master/internal/config/flags.go)
or run `gitlab-pages --help`.

### Running GitLab Pages manually

For any changes in the code, you must run `make` to build the app. It's best to just always run
it before you start the app. It's quick to build so don't worry!

```shell
make && ./gitlab-pages -config=gitlab-pages.conf
```

## Configuring GitLab Pages with GDK

In the following steps, `$GDK_ROOT` is the directory where you cloned GDK.

1. Set up the [GDK hostname](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/local_network.md).
1. Add a [GitLab Pages hostname](#configuring-gitlab-pages-hostname) to the `gdk.yml`:

   ```yaml
   gitlab_pages:
     enabled: true         # enable GitLab Pages to be managed by gdk
     port: 3010            # default port is 3010
     host: pages.gdk.test  # the GitLab Pages domain
     auto_update: true     # if gdk must update GitLab Pages git
     verbose: true         # show more information in the logs
   ```

### Running GitLab Pages with GDK

After these configurations are set, GDK manages a GitLab Pages process, giving you access to
it with commands like:

- Start: `gdk start gitlab-pages`
- Stop: `gdk stop gitlab-pages`
- Restart: `gdk restart gitlab-pages`
- Tail logs: `gdk tail gitlab-pages`

### Running GitLab Pages manually

You can also build and start the app independently of GDK processes management.

For any changes in the code, you must run `make` to build the app. It's best to just always run
it before you start the app. It's quick to build so don't worry!

```shell
make && ./gitlab-pages -config=gitlab-pages.conf
```

#### Building GitLab Pages in FIPS mode

```shell
FIPS_MODE=1 make && ./gitlab-pages -config=gitlab-pages.conf
```

### Creating GitLab Pages site

To build a GitLab Pages site locally you must
[configure `gitlab-runner`](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/runner.md).

For more information, refer to the [user manual](../../user/project/pages/_index.md).

### Enabling access control

GitLab Pages support private sites. Private sites can be accessed only by users
who have access to your GitLab project.

GitLab Pages access control is disabled by default. To enable it:

1. Enable the GitLab Pages access control in GitLab itself. You can do this in two ways:

   - If you're not using GDK, edit `gitlab.yml`:

     ```yaml
     # gitlab/config/gitlab.yml
     pages:
       access_control: true
     ```

   - If you're using GDK, edit `gdk.yml`:

     ```yaml
     # $GDK_ROOT/gdk.yml
     gitlab_pages:
       enabled: true
       access_control: true
     ```

1. Restart GitLab (if running through the GDK, run `gdk restart`). Running
   `gdk reconfigure` overwrites the value of `access_control` in `config/gitlab.yml`.
1. In your local GitLab instance, in the browser go to `http://gdk.test:3000/admin/applications`.
1. Create an [Instance-wide OAuth application](../../integration/oauth_provider.md#create-an-instance-wide-application)
   with the `api` scope.
1. Set the value of your `redirect-uri` to the `pages-domain` authorization endpoint
   (for example, `http://pages.gdk.test:3010/auth`).
   The `redirect-uri` must not contain any GitLab Pages site domain.

1. Add the auth client configuration:

   - With GDK, in `gdk.yml`:

     ```yaml
     gitlab_pages:
       enabled: true
       access_control: true
       auth_client_id: $CLIENT_ID           # the OAuth application id created in http://gdk.test:3000/admin/applications
       auth_client_secret: $CLIENT_SECRET   # the OAuth application secret created in http://gdk.test:3000/admin/applications
     ```

     GDK generates random `auth_secret` and builds the `auth_redirect_uri` based on GitLab Pages
     host configuration.

   - Without GDK, in `gitlab-pages.conf`:

     ```conf
     ## the following are only needed if you want to test auth for private projects
     auth-client-id=$CLIENT_ID                         # the OAuth application id created in http://gdk.test:3000/admin/applications
     auth-client-secret=$CLIENT_SECRET                 # the OAuth application secret created in http://gdk.test:3000/admin/applications
     auth-secret=$SOME_RANDOM_STRING                   # should be at least 32 bytes long
     auth-redirect-uri=http://pages.gdk.test:3010/auth # the authentication callback url for GitLab Pages
     ```

1. If running Pages inside the GDK, you can use GDK `protected_config_files` section under `gdk` in
   your `gdk.yml` to avoid getting `gitlab-pages.conf` configuration rewritten:

   ```yaml
   gdk:
     protected_config_files:
     - 'gitlab-pages/gitlab-pages.conf'
   ```

### Enabling object storage

GitLab Pages support using object storage for storing artifacts, but object storage
is disabled by default. You can enable it in the GDK:

1. Edit `gdk.yml` to enable the object storage in GitLab itself:

   ```yaml
   # $GDK_ROOT/gdk.yml
   object_store:
     enabled: true
   ```

1. Reconfigure and restart GitLab by running the commands `gdk reconfigure` and `gdk restart`.

For more information, refer to the [GDK documentation](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/configuration.md#object-storage-configuration).

## Linting

```shell
# Run the linter locally
make lint

# Run linter and fix issues (if supported by the linter)
make format
```

## Testing

To run tests, you can use these commands:

```shell
# This will run all of the tests in the codebase
make test

# Run a specfic test file
go test ./internal/serving/disk/

# Run a specific test in a file
go test ./internal/serving/disk/ -run TestDisk_ServeFileHTTP

# Run all unit tests except acceptance_test.go
go test ./... -short

# Run acceptance_test.go only
make acceptance
# Run specific acceptance tests
# We add `make` here because acceptance tests use the last binary that was compiled,
# so we want to have the latest changes in the build that is tested
make && go test ./ -run TestRedirect
```

## Contributing

### Feature flags

WARNING:
All newly-introduced feature flags should be [disabled by default](https://handbook.gitlab.com/handbook/product-development-flow/feature-flag-lifecycle/#how-to-use-feature-flags).

Consider adding a [feature flag](../feature_flags/_index.md) for any non-trivial changes.
Feature flags can make the release and rollback of these changes easier, avoiding
incidents and downtime. To add a new feature flag to GitLab Pages:

1. Create the feature flag in
   [`internal/feature/feature.go`](https://gitlab.com/gitlab-org/gitlab-pages/-/blob/master/internal/feature/feature.go),
   which must be **off** by default.
1. Create an issue to track the feature flag using the `Feature flag` template.
1. Add the `~"feature flag"` label to any merge requests that handle feature flags.

For GitLab Pages, the feature flags are controlled by environment variables at a global level.
A deployment at the service level is required to change the state of a feature flag.
Example of a merge request enabling a GitLab Pages feature flag:
[Enforce GitLab Pages rate limits](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/merge_requests/1500)

## Related topics

- [Feature flags in the development of GitLab](../feature_flags/_index.md)

## Becoming a GitLab Pages maintainer

This document serves as a guideline for GitLab team members that want to become maintainers for the GitLab Pages project.
Maintainers should have an advanced understanding of the GitLab Pages codebase.
Prior to applying for maintainer of a project, a person should gain a good feel for the codebase, expertise in one or more functionalities,
and deep understanding of our coding standards.

### Expectations

The process to [become a maintainer at GitLab is defined in the handbook](https://handbook.gitlab.com/handbook/engineering/workflow/code-review/#how-to-become-a-project-maintainer),
and it is the baseline for this process. One thing that is expected is a high number of reviews, however;
the rate of change of the GitLab Pages compared to the GitLab Rails project is too little.

To work around that problem, one must be comfortable in the following areas of the codebase:

Main areas:

- Namespace/project resolution
- ZIP serving and the virtual file system
- Authentication

Smaller areas:

- Redirects
- Artifacts proxying
- Handling of TLS certificates
- Rate-limiting
- Metrics and monitoring

To achieve this, you should try to make relevant contributions in all main areas and 2-3 smaller areas
mentioned above so that you have a better understanding of the functionality. A relevant contribution may be a bug fix,
a performance improvement, a new feature, or a significant refactoring.

### Reviewer

Prior to becoming a maintainer, you should first become a reviewer of the project. This should include changes
to any part of the codebase including the documentation.

To become a reviewer follow the steps [outlined in the handbook](https://handbook.gitlab.com/handbook/engineering/workflow/code-review/#reviewer).
There is no set timeline of how long you should be a reviewer before becoming a maintainer, but you should
gain enough experience in the areas mentioned in the [expectations section](#expectations) of this document.

### Maintainer

To become a maintainer follow the steps [outlined in the handbook](https://handbook.gitlab.com/handbook/engineering/workflow/code-review/#how-to-become-a-project-maintainer).
You are probably ready to become a maintainer when these statements feel true:

- The MRs you have reviewed consistently make it through maintainer review without significant additionally required changes
- The MRs you have created consistently make it through reviewer and maintainer review without significant required changes
- You feel comfortable working through operational tasks

If those subjective requirements are satisfied, [open an MR](https://gitlab.com/gitlab-com/www-gitlab-com/-/blob/master/.gitlab/merge_request_templates/Backend%20maintainer.md)
promoting you to maintainer and tag the existing maintainers.
