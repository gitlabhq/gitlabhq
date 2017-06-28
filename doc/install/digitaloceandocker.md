# Digital Ocean and Docker Machine test environment

## Warning. This guide is for quickly testing different versions of GitLab and
## not recommended for ease of future upgrades or keeping the data you create.

## Initial setup

In this guide you'll configure a Digital Ocean droplet and set up Docker
locally on either macOS or Linux.

### On macOS

#### Install Docker Toolbox

1. [https://www.docker.com/products/docker-toolbox](https://www.docker.com/products/docker-toolbox)

### On Linux

#### Install Docker Engine

1. [https://docs.docker.com/engine/installation/linux](https://docs.docker.com/engine/installation/linux/)

#### Install Docker Machine

1. [https://docs.docker.com/machine/install-machine](https://docs.docker.com/machine/install-machine/)

_The rest of the steps are identical for macOS and Linux_

### Create new docker host

1. Login to Digital Ocean
1. Generate a new API token at https://cloud.digitalocean.com/settings/api/tokens


This command will create a new DO droplet called `gitlab-test-env-do` that will act as a docker host.

**Note: 4GB is the minimum requirement for a Docker host that will run more then one GitLab instance**

+ RAM: 4GB
+ Name: `gitlab-test-env-do`
+ Driver: `digitalocean`


**Set the DO token** - Replace the string below with your generated token

```
export DOTOKEN=cf3dfd0662933203005c4a73396214b7879d70aabc6352573fe178d340a80248
```

**Create the machine**

```
docker-machine create \
  --driver digitalocean \
  --digitalocean-access-token=$DOTOKEN \
  --digitalocean-size "4gb" \
    gitlab-test-env-do
```

+ Resource: https://docs.docker.com/machine/drivers/digital-ocean/


### Creating GitLab test instance


#### Connect your shell to the new machine


In this example we'll create a GitLab EE 8.10.8 instance.


First connect the docker client to the docker host you created previously.

```
eval "$(docker-machine env gitlab-test-env-do)"
```

You can add this to your `~/.bash_profile` file to ensure the `docker` client uses the `gitlab-test-env-do` docker host


#### Create new GitLab container

+ HTTP port: `8888`
+ SSH port: `2222`
   + Set `gitlab_shell_ssh_port` using `--env GITLAB_OMNIBUS_CONFIG `
+ Hostname: IP of docker host
+ Container name: `gitlab-test-8.10`
+ GitLab version: **EE** `8.10.8-ee.0`

#####  Setup container settings

```
export SSH_PORT=2222
export HTTP_PORT=8888
export VERSION=8.10.8-ee.0
export NAME=gitlab-test-8.10
```

#####  Create container
```
docker run --detach \
--env GITLAB_OMNIBUS_CONFIG="external_url 'http://$(docker-machine ip gitlab-test-env-do):$HTTP_PORT'; gitlab_rails['gitlab_shell_ssh_port'] = $SSH_PORT;" \
--hostname $(docker-machine ip gitlab-test-env-do) \
-p $HTTP_PORT:$HTTP_PORT -p $SSH_PORT:22 \
--name $NAME \
gitlab/gitlab-ee:$VERSION
```

#### Connect to the GitLab container

##### Retrieve the docker host IP

```
docker-machine ip gitlab-test-env-do
# example output: 192.168.151.134
```


+ Browse to: http://192.168.151.134:8888/


##### Execute interactive shell/edit configuration


```
docker exec -it $NAME /bin/bash
```

```
# example commands
root@192:/# vi /etc/gitlab/gitlab.rb
root@192:/# gitlab-ctl reconfigure
```

#### Resources

+ [https://docs.gitlab.com/omnibus/docker/](https://docs.gitlab.com/omnibus/docker/)
+ [https://docs.docker.com/machine/get-started/](https://docs.docker.com/machine/get-started/)
+ [https://docs.docker.com/machine/reference/ip/](https://docs.docker.com/machine/reference/ip/)+
