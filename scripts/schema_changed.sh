#!/bin/sh

schema_changed() {
  if [ ! -z "$(git diff --name-only -- db/structure.sql)" ]; then
    printf "db/structure.sql after rake db:migrate:reset is different from one in the repository"
    printf "The diff is as follows:\n"
    diff=$(git diff -p --binary -- db/structure.sql)
    printf "%s" "$diff"
    exit 1
  else
    printf "db/structure.sql after rake db:migrate:reset matches one in the repository"
  fi
}

schema_changed
