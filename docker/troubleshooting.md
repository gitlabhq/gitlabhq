# Troubleshooting

This is to troubleshoot https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/245
But it might contain useful commands for other cases as well.

The configuration to add the postgres log in vim is:
postgresql['log_directory'] = '/var/log/gitlab/postgresql.log'

# Commands

sudo docker rm -f gitlab
sudo docker rm -f gitlab_data

sudo docker build --tag gitlab_image docker/
sudo docker run --name gitlab_data gitlab_image /bin/true

sudo docker run -ti --rm --volumes-from gitlab_data ubuntu apt-get update && sudo apt-get install -y vim && sudo vim /etc/gitlab/gitlab.rb

sudo docker run --detach --name gitlab --publish 8080:80 --publish 2222:22 --volumes-from gitlab_data gitlab_image

sudo docker run -t --rm --volumes-from gitlab_data ubuntu tail -f /var/log/gitlab/reconfigure.log

sudo docker run -t --rm --volumes-from gitlab_data ubuntu cat /var/log/gitlab/postgresql.log
