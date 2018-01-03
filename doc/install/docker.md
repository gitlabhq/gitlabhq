# GitLab Docker images

[Docker](https://www.docker.com) and container technology have been revolutionizing the software world for the past few years. They combine the performance and efficiency of native execution with the abstraction, security, and immutability of virtualization.

GitLab provides official Docker images to allowing you to easily take advantage of the benefits of containerization while operating your GitLab instance.

## Omnibus GitLab based images

GitLab maintains a set of [official Docker images](https://hub.docker.com/r/gitlab) based on our [Omnibus GitLab package](https://docs.gitlab.com/omnibus/README.html). These images include:
* [GitLab Community Edition](https://hub.docker.com/r/gitlab/gitlab-ce/)
* [GitLab Enterprise Edition](https://hub.docker.com/r/gitlab/gitlab-ee/)
* [GitLab Runner](https://hub.docker.com/r/gitlab/gitlab-runner/)

A [complete usage guide](https://docs.gitlab.com/omnibus/docker/) to these images is available, as well as the [Dockerfile used for building the images](https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master/docker).

## Cloud native images

GitLab is also working towards a [cloud native set of containers](https://gitlab.com/charts/helm.gitlab.io#docker-container-images), with a single image for each component service. We intend for these images to eventually replace the [Omnibus GitLab based images](#omnibus-gitlab-based-images).
