#!/bin/bash
FILE=/tmp/install_done

if [ -f $FILE ]
then
	echo "File $FILE exists..."
else
	source /var/.cloud66_env
	apt-get install libicu-dev -y
    apt-get install acl -y
    sudo touch /tmp/install_done
fi





