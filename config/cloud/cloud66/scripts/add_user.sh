#!/bin/bash
FILE=/tmp/add_user_done

if [ -f $FILE ]
then
	echo "File $FILE exists..."
else
	chmod 666 /var/.cloud66_env
	source /var/.cloud66_env
    sudo adduser --disabled-login --gecos 'GitLab' --ingroup app_writers git
    sudo touch /tmp/add_user_done
fi