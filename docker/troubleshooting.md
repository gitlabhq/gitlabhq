# Troubleshooting

This is to troubleshoot https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/245
But it might contain useful commands for other cases as well.

The configuration to add the postgres log in vim is:
postgresql['log_directory'] = '/var/log/gitlab/postgresql'

# Commands

```bash
sudo docker build --tag gitlab_image docker/

sudo docker rm -f gitlab_app
sudo docker rm -f gitlab_data

sudo docker run --name gitlab_data gitlab_image /bin/true

sudo docker run -ti --rm --volumes-from gitlab_data ubuntu apt-get update && sudo apt-get install -y vim && sudo vim /etc/gitlab/gitlab.rb

sudo docker run --detach --name gitlab_app --publish 8080:80 --publish 2222:22 --volumes-from gitlab_data gitlab_image

sudo docker run -t --rm --volumes-from gitlab_data ubuntu tail -f /var/log/gitlab/reconfigure.log

sudo docker run -t --rm --volumes-from gitlab_data ubuntu tail -f /var/log/gitlab/postgresql/current

sudo docker run -t --rm --volumes-from gitlab_data ubuntu cat /var/opt/gitlab/postgresql/data/postgresql.conf | grep shared_buffers

sudo docker run -t --rm --volumes-from gitlab_data ubuntu cat /etc/gitlab/gitlab.rb
```

# Interactively

```bash
# First start a GitLab container without starting GitLab
# This is almost the same as starting the GitLab container except:
# - we run interactively (-t -i)
# - we define TERM=linux because it allows to use arrow keys in vi (!!!)
# - we choose another startup command (bash)
sudo docker run -ti -e TERM=linux --name gitlab_app --publish 8080:80 --publish 2222:22 --volumes-from gitlab_data gitlab_image bash

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
