#!/bin/bash
FILE=/tmp/permissions_done

if [ -f $FILE ]
then
	echo "File $FILE exists..."
else
	source /var/.cloud66_env
    chmod 666 /var/.cloud66_env
    cd $STACK_PATH
    sudo chown -R git:app_writers log
    sudo chown -R git:app_writers tmp/
    sudo chown -R git:app_writers public/uploads
    sudo chmod -R u+rwX,g+rwX log
    sudo chmod -R u+rwX,g+rwX tmp/
    sudo chmod -R u+rwX,g+rwX public/uploads
    sudo -u git -H mkdir /home/git/gitlab-satellites
    sudo mkdir /home/git/repositories
    sudo chown -R git:app_writers /home/git/repositories/
    sudo chmod -R g+rwX /home/git/repositories
    sudo setfacl -d -m u:git:rwX,g:app_writers:rwX /home/git/repositories
    sudo chmod g+s /home/git/repositories
    sudo touch /tmp/permissions_done
fi
