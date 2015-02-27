#!/bin/sh

set -e

for file in config/*.yml.example; do
  cp ${file} config/$(basename ${file} .example)
done

# Allow to override the Gitlab URL from an environment variable, as this will avoid having to change the configuration file for simple deployments.
config=$(echo '<% gitlab_url = URI(ENV["GITLAB_URL"] || "http://localhost:80") %>' | cat - config/gitlab.yml)
echo "$config" > config/gitlab.yml
sed -i "s/host: localhost/host: <%= gitlab_url.host %>/" config/gitlab.yml
sed -i "s/port: 80/port: <%= gitlab_url.port %>/" config/gitlab.yml
sed -i "s/https: false/https: <%= gitlab_url.scheme == 'https' %>/" config/gitlab.yml

# No need for config file. Will be taken care of by REDIS_URL env variable
rm config/resque.yml

# Set default unicorn.rb file
echo "" > config/unicorn.rb
