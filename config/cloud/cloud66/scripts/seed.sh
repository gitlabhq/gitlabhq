#!/bin/bash
FILE=/tmp/seed_done

if [ -f $FILE ]
then
	echo "File $FILE exists..."
else
	source /var/.cloud66_env
	cd $STACK_PATH
	yes yes | bundle exec rake gitlab:setup RAILS_ENV=production
	sudo touch /tmp/seed_done
fi
