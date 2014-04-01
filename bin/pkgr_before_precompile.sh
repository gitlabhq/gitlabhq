#!/bin/sh

set -ex

for file in config/*.yml.example; do
  cp ${file} config/$(basename ${file} .example)
done

# No need for config file. Will be taken care of by REDIS_URL env variable
rm config/resque.yml

# Set default unicorn.rb file
echo "" > config/unicorn.rb

# Required for assets precompilation
sudo service postgresql start
