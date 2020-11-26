---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
comments: false
type: index
---

# GitLab CI services examples

The [`services`](../docker/using_docker_images.md#what-is-a-service)
keyword defines a Docker image that runs during a `job` linked to the
Docker image that the image keyword defines. This allows you to access
the service image during build time.

The service image can run any application, but the most common use
case is to run a database container, for example:

- [Using MySQL](mysql.md)
- [Using PostgreSQL](postgres.md)
- [Using Redis](redis.md)
