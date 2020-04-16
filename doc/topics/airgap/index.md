# Offline GitLab

Computers in an offline environment are isolated from the public internet as a security measure. This
page lists all the information available for running GitLab in an offline environment.

## Quick start

If you plan to deploy a GitLab instance on a physically-isolated and offline network, see the
[quick start guide](quick_start_guide.md) for configuration steps.

## Features

Follow these best practices to use GitLab's features in an offline environment:

- [Operating the GitLab Secure scanners in an offline environment](../../user/application_security/offline_deployments/index.md).

## Loading Docker images onto your offline host

To use many GitLab features, including
[security scans](../../user/application_security/index.md#working-in-an-offline-environment)
and [Auto DevOps](../autodevops/), the GitLab Runner must be able to fetch the
relevant Docker images.

The process for making these images available without direct access to the public internet
involves downloading the images then packaging and transferring them to the offline host. Here's an
example of such a transfer:

1. Download Docker images from public internet.
1. Package Docker images as tar archives.
1. Transfer images to offline environment.
1. Load transferred images into offline Docker registry.

### Example image packager script

```sh
#!/bin/bash
set -ux

# Specify needed analyzer images
analyzers=${SAST_ANALYZERS:-"bandit eslint gosec"}
gitlab=registry.gitlab.com/gitlab-org/security-products/analyzers/

for i in "${analyzers[@]}"
do
  tarname="${i}_2.tar"
  docker pull $gitlab$i:2
  docker save $gitlab$i:2 -o ./analyzers/${tarname}
  chmod +r ./analyzers/${tarname}
done
```

### Example image loader script

This example loads the images from a bastion host to an offline host. In certain configurations,
physical media may be needed for such a transfer:

```sh
#!/bin/bash
set -ux

# Specify needed analyzer images
analyzers=${SAST_ANALYZERS:-"bandit eslint gosec"}
registry=$GITLAB_HOST:4567

for i in "${analyzers[@]}"
do
  tarname="${i}_2.tar"
  scp ./analyzers/${tarname} ${GITLAB_HOST}:~/${tarname}
  ssh $GITLAB_HOST "sudo docker load -i ${tarname}"
  ssh $GITLAB_HOST "sudo docker tag $(sudo docker images | grep $i | awk '{print $3}') ${registry}/analyzers/${i}:2"
  ssh $GITLAB_HOST "sudo docker push ${registry}/analyzers/${i}:2"
done
```
