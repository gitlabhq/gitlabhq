#!/bin/bash
FILE=/tmp/dev_seed_done

if [ -f $FILE ]
then
	echo "File $FILE exists..."
else
	source /var/.cloud66_env
    cd $RAILS_STACK_PATH
    bundle exec rake dev:setup
    sudo touch /tmp/dev_seed_done
fi