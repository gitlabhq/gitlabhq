#!/bin/bash

echo "Danger!!! Data Loss"
while true; do
  read -p "Do you wish to all directories except gitolite-admin.git from /home/git/repositories/ (y/n) ?:  " yn
  case $yn in
    [Yy]* ) sh -c "find /home/git/repositories/. -maxdepth 1  -not -name 'gitolite-admin.git' -not -name '.' | xargs sudo rm -rf"; break;;
    [Nn]* ) exit;;
    * ) echo "Please answer yes or no.";;
  esac
done
