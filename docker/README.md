# GitLab Docker images

## What is GitLab?

GitLab offers git repository management, code reviews, issue tracking, activity feeds, wikis. It has LDAP/AD integration, handles 25,000 users on a single server but can also run on a highly available active/active cluster.
Learn more on [https://about.gitlab.com](https://about.gitlab.com)

## After starting a container

After starting a container you can go to [http://localhost:8080/](http://localhost:8080/) or [http://192.168.59.103:8080/](http://192.168.59.103:8080/) if you use boot2docker.

It might take a while before the docker container is responding to queries.

You can check the status with something like `sudo docker logs -f 7c10172d7705`.

You can login to the web interface with username `root` and password `5iveL!fe`.

Next time, you can just use docker start and stop to run the container.

## How to build the docker images

This guide will also let you know how to build docker images yourself.
Please run all the commands from the GitLab repo root directory.
People using boot2docker should run all the commands without sudo.

## Choosing between the single and the app and data images

Normally docker uses a single image for one applications.
But GitLab stores repositories and uploads in the filesystem.
This means that upgrades of a single image are hard.
That is why we recommend using separate app and data images.
We'll first describe how to use a single image.
After that we'll describe how to use the app and data images.

## Single image

Get a published image from Dockerhub:

```bash
sudo docker pull sytse/gitlab-ce:7.10.1
```

Run the image:

```bash
sudo docker run --detach --publish 8080:80 --publish 2222:22 sytse/gitlab-ce:7.10.1
```

After this you can login to the web interface as explained above in 'After starting a container'.

Build the image:

```bash
sudo docker build --tag sytse/gitlab-ce:7.10.1 docker/single/
```

Publish the image to Dockerhub:

```bash
sudo docker push sytse/gitlab-ce
```

Diagnosing commands:

```bash
sudo docker run -i -t sytse/gitlab-ce:7.10.1
sudo docker run -ti -e TERM=linux --name gitlab-ce-troubleshoot --publish 8080:80 --publish 2222:22 sytse/gitlab-ce:7.10.1 bash /usr/local/bin/wrapper
```

## App and data images

### Get published images from Dockerhub

```bash
sudo docker pull sytse/gitlab-data
sudo docker pull sytse/gitlab-app:7.10.1
```

### Run the images

```bash
sudo docker run --name gitlab-data sytse/gitlab-data /bin/true
sudo docker run --detach --name gitlab_app --publish 8080:80 --publish 2222:22 --volumes-from gitlab_data sytse/gitlab-app:7.10.1
```

After this you can login to the web interface as explained above in 'After starting a container'.

### Build images

Build your own based on the Omnibus packages with the following commands.

```bash
sudo docker build --tag gitlab-data docker/data/
sudo docker build --tag gitlab-app:7.10.1 docker/app/
```

After this run the images as described in the previous section.

We assume using a data volume container, this will simplify migrations and backups.
This empty container will exist to persist as volumes the 3 directories used by GitLab, so remember not to delete it.

The directories on data container are:

- `/var/opt/gitlab` for application data
- `/var/log/gitlab` for logs
- `/etc/gitlab` for configuration

### Configure GitLab

This container uses the official Omnibus GitLab distribution, so all configuration is done in the unique configuration file `/etc/gitlab/gitlab.rb`.

To access GitLab configuration, you can start an interactive command line in a new container using the shared data volume container, you will be able to browse the 3 directories and use your favorite text editor:

```bash
sudo docker run -ti -e TERM=linux --rm --volumes-from gitlab-data ubuntu
vi /etc/gitlab/gitlab.rb
```

**Note** that GitLab will reconfigure itself **at each container start.** You will need to restart the container to reconfigure your GitLab.

You can find all available options in [Omnibus GitLab documentation](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/README.md#configuration).

### Upgrade GitLab with app and data images

To upgrade GitLab to new versions, stop running container, create new docker image and container from that image.

It Assumes that you're upgrading from 7.8.1 to 7.10.1 and you're in the updated GitLab repo root directory:

```bash
sudo docker stop gitlab-app
sudo docker rm gitlab-app
sudo docker build --tag gitlab-app:7.10.1 docker/app/
sudo docker run --detach --name gitlab-app --publish 8080:80 --publish 2222:22 --volumes-from gitlab_data gitlab-app:7.10.1
```

On the first run GitLab will reconfigure and update itself. If everything runs OK don't forget to cleanup the app image:

```bash
sudo docker rmi gitlab-app:7.8.1
```

### Publish images to Dockerhub

- Ensure the containers are running
- Login to Dockerhub with `sudo docker login`
- Run the following (replace '7.9.2' with the version you're using and 'Sytse Sijbrandij' with your name):

```bash
sudo docker commit -m "Initial commit" -a "Sytse Sijbrandij" gitlab-app sytse/gitlab-app:7.10.1
sudo docker push sytse/gitlab-app:7.10.1
sudo docker commit -m "Initial commit" -a "Sytse Sijbrandij" gitlab_data sytse/gitlab_data
sudo docker push sytse/gitlab_data
```

## Troubleshooting

Please see the [troubleshooting](troubleshooting.md) file in this directory.