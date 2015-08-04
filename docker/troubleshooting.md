# Troubleshooting

This is to troubleshoot https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/245
But it might contain useful commands for other cases as well.

The configuration to add the postgres log in vim is:
postgresql['log_directory'] = '/var/log/gitlab/postgresql'

# Commands

```bash
sudo docker build --tag gitlab/gitlab-ce:latest docker/

sudo docker rm -f gitlab

sudo docker exec -it gitlab vim /etc/gitlab/gitlab.rb

sudo docker exec gitlab tail -f /var/log/gitlab/reconfigure.log

sudo docker exec gitlab tail -f /var/log/gitlab/postgresql/current

sudo docker exec gitlab cat /var/opt/gitlab/postgresql/data/postgresql.conf | grep shared_buffers

sudo docker exec gitlab cat /etc/gitlab/gitlab.rb
```

# Interactively

```bash
# First start a GitLab container without starting GitLab
# This is almost the same as starting the GitLab container except:
# - we run interactively (-t -i)
# - we define TERM=linux because it allows to use arrow keys in vi (!!!)
# - we choose another startup command (bash)
sudo docker run --ti \
    -e TERM=linux
	--publish 80443:443 --publish 8080:80 --publish 2222:22 \
	--name gitlab \
	--restart always \
	--volume /srv/gitlab/config:/etc/gitlab \
	--volume /srv/gitlab/logs:/var/log/gitlab \
	--volume /srv/gitlab/data:/var/opt/gitlab \
	gitlab/gitlab-ce:latest \
	bash

# Configure GitLab to redirect PostgreSQL logs
echo "postgresql['log_directory'] = '/var/log/gitlab/postgresql'" >> /etc/gitlab/gitlab.rb

# Prevent Postgres from allocating 25% of total memory
echo "postgresql['shared_buffers'] = '1MB'" >> /etc/gitlab/gitlab.rb

# You can now start GitLab manually from Bash (in the background)
# Maybe the command below is still missing something to run in the background
gitlab-ctl reconfigure > /var/log/gitlab/reconfigure.log & /opt/gitlab/embedded/bin/runsvdir-start &

# Inspect PostgreSQL config
cat /var/opt/gitlab/postgresql/data/postgresql.conf | grep shared_buffers

# And tail the logs (PostgreSQL log may not exist immediately)
tail -f /var/log/gitlab/reconfigure.log /var/log/gitlab/postgresql/current

# And get the memory
cat /proc/meminfo
head /proc/sys/kernel/shmmax /proc/sys/kernel/shmall
free -m

```

# Cleanup

Remove ALL docker containers and images (also non GitLab ones).
**Be careful, because the `-v` also removes volumes attached to the images.**

```bash
# Remove all containers with attached volumes
docker rm -v $(docker ps -a -q)

# Remove all images
docker rmi $(docker images -q)

# Remove GitLab persistent data
rm -rf /srv/gitlab
```

