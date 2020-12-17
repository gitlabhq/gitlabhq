---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: index
---

# Install GitLab with Docker

[Docker](https://www.docker.com) and container technology have been revolutionizing the software world for the past few years. They combine the performance and efficiency of native execution with the abstraction, security, and immutability of virtualization.

GitLab provides official Docker images allowing you to easily take advantage of the benefits of containerization while operating your GitLab instance. A [complete usage guide](https://docs.gitlab.com/omnibus/docker/) for these images is available, as well as the [Dockerfile used for building the images](https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master/docker).

There's also a [Docker image for GitLab Runner](https://docs.gitlab.com/runner/install/docker.html).

## Cloud native images

GitLab is also working towards a [cloud native set of containers](https://docs.gitlab.com/charts/), with a single image for each component service.
