#!/bin/sh
# This script copies the necessary .yml and .rb config files, based of the .example files.

set -ex

for file in config/*.example; do
  cp $file config/$(basename $file .example)
done

cp config/database.yml{.mysql,}
