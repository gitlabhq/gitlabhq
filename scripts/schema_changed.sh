#!/bin/sh

schema_changed() {
  if [ ! -z "$(git diff --name-only -- db/structure.sql)" ]; then
    printf "Schema changes are not cleanly committed to db/structure.sql\n"
    printf "The diff is as follows:\n"
    diff=$(git diff -p --binary -- db/structure.sql)
    printf "%s" "$diff"
    exit 1
  else
    printf "Schema changes are correctly applied to db/structure.sql\n"
  fi
}

schema_changed
