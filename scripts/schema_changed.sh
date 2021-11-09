#!/bin/sh

if [ -n "$(git diff --name-only -- db/structure.sql)" ]; then
  printf "Schema changes are not cleanly committed to db/structure.sql\n"
  printf "The diff is as follows:\n"
  diff=$(git diff -p --binary -- db/structure.sql)
  printf "%s" "$diff"
  exit 1
else
  printf "Schema changes are correctly applied to db/structure.sql\n"
fi

if [ -n "$(git add -A -n db/schema_migrations)" ]; then
  printf "Schema version files have not been committed to the repository:\n"
  printf "The following files should be committed:\n"
  diff=$(git add -A -n db/schema_migrations)
  printf "%s" "$diff"
  exit 2
else
  printf "Schema changes are correctly applied to db/structure.sql and db/schema_migrations/\n"
fi
