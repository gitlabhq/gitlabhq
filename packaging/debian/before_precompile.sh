#!/bin/sh

set -ex

for file in config/*.example; do
  cp $file config/$(basename $file .example)
done

cp config/database.yml{.mysql,}
