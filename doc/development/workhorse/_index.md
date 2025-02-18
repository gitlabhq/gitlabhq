---
stage: Create
group: Source Code
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: GitLab Workhorse
---

GitLab Workhorse is a smart reverse proxy for GitLab intended to handle resource-intensive and long-running requests.
It sits in front of Puma and intercepts every HTTP request destined for and emitted from GitLab Rails.
Rails delegates requests to Workhorse and it takes responsibility for resource intensive HTTP requests
such as file downloads and uploads, `git` over HTTP push/pull and `git` over HTTP archive downloads,
which optimizes resource utilization and improves request handling efficiency.

## Role in the GitLab stack

Workhorse can have other reverse proxy servers in front of it but only NGINX is supported.
It is also possible (although unsupported) to use other reverse proxies such as Apache when installing
GitLab from source.
On many instances of GitLab, such as `gitlab.com`, a CDN like CloudFlare sits in front of NGINX.

Every Rails controller and other code that handles HTTP requests and returning HTTP responses is
proxied through GitLab Workhorse.
Workhorse is unlike other reverse proxies as it is tightly coupled to GitLab Rails, whereas most reverse
proxies are more generic.
When required, Workhorse makes modifications to HTTP headers which GitLab Rails depends on to offload work efficiently.

## Functionality and operations

### Request processing

- Workhorse primarily acts as a pass-through entity for incoming requests, forwarding them to Rails for processing.
  In essence, it performs minimal intervention on most requests, thereby maintaining a streamlined
  request handling pipeline.
- For specific types of requests, especially those that are resource-intensive or require specialized handling
  (for example, large file uploads), Workhorse takes a more active role.
  Upon receiving directives from Rails, Workhorse executes specialized tasks such as directly
  interacting with [Gitaly](../../administration/gitaly/_index.md) or offloading processing file uploads from Rails.

### Specialized task handling

- Workhorse is capable of intercepting certain requests based on Rails' responses and executing
  predefined operations.
  This includes interacting with [Gitaly](../../administration/gitaly/_index.md), managing large data
  blobs, and altering request handling logic as required.
- Workhorse can manage file uploads efficiently.
  It can hijack the file upload process, perform necessary actions as dictated by Rails
  (such as storing files temporarily or uploading them to object storage), and update Rails when the
  process has completed.

### Integration with the Rails API

Workhorse serves as a proxy to the Rails API, especially in contexts requiring interaction with container
registry services.
This setup exemplifies Workhorse's handling of high-load services by acting as a reverse proxy,
thereby minimizing the direct load on Rails.

## Architectural considerations

### Expanding functionality

- **Maintaining Simplicity:** While expanding Workhorse's functionalities to include direct handling
  of specific services (for example, container registry), it's crucial to maintain its simplicity and efficiency.
  Workhorse should not encompass complex control logic but rather focus on executing tasks as directed
  by Rails.
- **Service Implementation and Data Migration:** Implementing new functionalities in Workhorse
  requires careful consideration of data migration strategies and service continuity.

### Data management and operational integrity

- Workhorse's architecture facilitates efficient data management strategies, including garbage
  collection and data migration.
  Workhorse's role is to support high-performance operations without directly involving complex data
  manipulation or control logic, which remains the purview of Rails.
- For operations requiring background processing or long-running tasks, it is suggested to use
  separate services or Sidekiq job queues, with Workhorse and Rails coordinating to manage task execution and data integrity.

Workhorse is contained in a subfolder of the Rails monorepo at
[`gitlab-org/gitlab/workhorse`](https://gitlab.com/gitlab-org/gitlab/tree/master/workhorse).

## Learning resources

- Workhorse documentation (this page)
- Video: [GitLab Workhorse Deep Dive: Dependency Proxy](https://www.youtube.com/watch?v=9cRd-k0TRqI)
- [How Dependency Proxy with Workhorse works](https://gitlab.com/gitlab-org/gitlab/-/issues/370235)
- [Workhorse overview for the Dependency Proxy](https://www.youtube.com/watch?v=WmBibT9oQms)
- [Workhorse architecture discussion](https://www.youtube.com/watch?v=QlHdh-yudtw)

## Install Workhorse

To install GitLab Workhorse you need [Go 1.18 or newer](https://go.dev/dl) and
[GNU Make](https://www.gnu.org/software/make/).

To install into `/usr/local/bin` run `make install`.

```plaintext
make install
```

To install into `/foo/bin` set the PREFIX variable.

```plaintext
make install PREFIX=/foo
```

On some operating systems, such as FreeBSD, you may have to use
`gmake` instead of `make`.

*NOTE*: Some features depends on build tags, make sure to check
[Workhorse configuration](configuration.md) to enable them.

### Run time dependencies

Workhorse uses [ExifTool](https://exiftool.org/) for
removing EXIF data (which may contain sensitive information) from uploaded
images. If you installed GitLab:

- Using the Linux package, you're all set.
  If you are using CentOS Minimal, you may need to install `perl` package: `yum install perl`.
- From source, make sure `exiftool` is installed:

  ```shell
  # Debian/Ubuntu
  sudo apt-get install libimage-exiftool-perl

  # RHEL/CentOS
  sudo yum install perl-Image-ExifTool
  ```

## Testing your code

Run the tests with:

```plaintext
make clean test
```

Each feature in GitLab Workhorse should have an integration test that
verifies that the feature 'kicks in' on the right requests and leaves
other requests unaffected. It is better to also have package-level tests
for specific behavior but the high-level integration tests should have
the first priority during development.

It is OK if a feature is only covered by integration tests.
