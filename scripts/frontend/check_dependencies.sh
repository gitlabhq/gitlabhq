#!/usr/bin/env bash

if ! yarn check --integrity 2>&1 > /dev/null
then
  echo
  echo "    $(tput setaf 1)yarn check --integrity$(tput sgr0) failed!"
  echo "    Your dependencies probably don't match the yarn.lock file."
  echo "    Please run $(tput setaf 2)yarn install$(tput sgr0) and try again."
  echo
  exit 1
fi
