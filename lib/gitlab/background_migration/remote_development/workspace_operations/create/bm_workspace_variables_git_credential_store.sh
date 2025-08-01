#!/bin/sh
# This is a readonly store so we can exit cleanly when git attempts a store or erase action
if [ "$1" != "get" ];
then
  exit 0
fi

if [ -z "${GL_TOKEN_FILE_PATH}" ];
then
  echo "$(date -Iseconds): We could not find the GL_TOKEN_FILE_PATH variable" >&2
  exit 1
fi
password=$(cat "${GL_TOKEN_FILE_PATH}")

# The username is derived from the "user.email" configuration item. Ensure it is set.
echo "username=does-not-matter"
echo "password=${password}"
exit 0
