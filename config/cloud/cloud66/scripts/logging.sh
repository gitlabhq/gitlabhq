#!/bin/bash
FILE=/tmp/logging_done

if [ -f $FILE ]
then
	echo "File $FILE exists..."
else
	source /var/.cloud66_env
    chmod 666 /var/.cloud66_env
    sudo touch /home/git/gitlab-shell/gitlab-shell.log
    sudo chown -R git:app_writers /home/git/gitlab-shell/gitlab-shell.log
    sudo chmod g+rwX /home/git/gitlab-shell/gitlab-shell.log
    sudo -u git -H git config --global user.name "GitLab"
    sudo -u git -H git config --global user.email "gitlab@localhost"
    sudo -u git -H git config --global core.autocrlf input
    sudo touch $RAILS_STACK_PATH/log/application.log
    sudo chown -R git:app_writers $RAILS_STACK_PATH/log/application.log
    sudo chmod g+rwX $RAILS_STACK_PATH/log/application.log
    sudo touch /tmp/logging_done
fi
