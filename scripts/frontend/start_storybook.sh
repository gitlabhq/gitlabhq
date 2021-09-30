#!/bin/bash

bold=$(tput bold)
normal=$(tput sgr0)

echo -e "Storybook provides a mock server that allows creating stories for components that make HTTP requests."
echo -e "${bold}Storybook will fail to start if it can’t find the fixtures used by the mock server.${normal}\n"
read -rp "Would you like to generate/update the frontend fixtures used by the mock server (y/N)? " answer

if [[ "$answer" =~ ^(Y|y)$ ]] ; then
  bundle exec rake frontend:mock_server_fixtures
fi

if ! [[ -d storybook/node_modules ]] ; then
  yarn storybook:install
fi

yarn --cwd ./storybook start
