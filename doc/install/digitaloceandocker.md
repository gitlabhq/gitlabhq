---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: howto
---

# Digital Ocean and Docker Machine test environment **(FREE SELF)**

This guide is for quickly testing different versions of GitLab and not
recommended for ease of future upgrades or keeping the data you create.

## Initial setup

This guide configures a Digital Ocean droplet and sets up Docker
locally on either macOS or Linux.

### On macOS

#### Install Docker Desktop

- <https://www.docker.com/products/docker-desktop>

### On Linux

#### Install Docker Engine

- <https://docs.docker.com/engine/installation/linux/>

#### Install Docker Machine

- <https://docs.docker.com/machine/install-machine/>

NOTE:
The rest of the steps are identical for macOS and Linux.

## Create new Docker host

1. Login to Digital Ocean.
1. Generate a new API token at <https://cloud.digitalocean.com/settings/api/tokens>.

   This command creates a new Digital Ocean droplet called `gitlab-test-env-do` that acts as a Docker host.

   NOTE:
   4GB is the minimum requirement for a Docker host that runs more than one GitLab instance.

   - RAM: 4GB
   - Name: `gitlab-test-env-do`
   - Driver: `digitalocean`

1. Set the DO token:

   ```shell
   export DOTOKEN=<your generated token>
   ```

1. Create the machine:

   ```shell
   docker-machine create \
     --driver digitalocean \
     --digitalocean-access-token=$DOTOKEN \
     --digitalocean-size "4gb" \
       gitlab-test-env-do
   ```

Resource: <https://docs.docker.com/machine/drivers/digital-ocean/>.

## Creating GitLab test instance

### Connect your shell to the new machine

This example creates a GitLab EE 8.10.8 instance.

First connect the Docker client to the Docker host you created previously.

```shell
eval "$(docker-machine env gitlab-test-env-do)"
```

You can add this to your `~/.bash_profile` file to ensure the `docker` client uses the `gitlab-test-env-do` Docker host

### Create new GitLab container

- HTTP port: `8888`
- SSH port: `2222`
  - Set `gitlab_shell_ssh_port` using `--env GITLAB_OMNIBUS_CONFIG`
- Hostname: IP of Docker host
- Container name: `gitlab-test-8.10`
- GitLab version: **EE** `8.10.8-ee.0`

#### Set up container settings

```shell
export SSH_PORT=2222
export HTTP_PORT=8888
export VERSION=8.10.8-ee.0
export NAME=gitlab-test-8.10
```

#### Create container

```shell
docker run --detach \
--env GITLAB_OMNIBUS_CONFIG="external_url 'http://$(docker-machine ip gitlab-test-env-do):$HTTP_PORT'; gitlab_rails['gitlab_shell_ssh_port'] = $SSH_PORT;" \
--hostname $(docker-machine ip gitlab-test-env-do) \
-p $HTTP_PORT:$HTTP_PORT -p $SSH_PORT:22 \
--name $NAME \
gitlab/gitlab-ee:$VERSION
```

### Connect to the GitLab container

#### Retrieve the Docker host IP

```shell
docker-machine ip gitlab-test-env-do
# example output: 192.168.151.134
```

Browse to: `http://192.168.151.134:8888/`.

#### Execute interactive shell/edit configuration

```shell
docker exec -it $NAME /bin/bash
```

```shell
# example commands
root@192:/# vi /etc/gitlab/gitlab.rb
root@192:/# gitlab-ctl reconfigure
```

### Resources

- <https://docs.gitlab.com/omnibus/docker/>.
- <https://docs.docker.com/machine/get-started/>.
- <https://docs.docker.com/machine/reference/ip/>.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
