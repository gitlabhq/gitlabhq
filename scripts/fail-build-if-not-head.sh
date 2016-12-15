#!/bin/sh

# accept master
if [ "$CI_BUILD_REF_NAME" -eq "master" ]; then
  exit 0
fi

# accept tags
if [ -n "$CI_BUILD_TAG" ]; then
  exit 0
fi

# accept `-stable`
if expr "$CI_BUILD_REF_NAME" : ".*-stable.*" > /dev/null; then
  exit 0
fi

HEAD_REF="$(git rev-parse "origin/$CI_BUILD_REF_NAME")"

if [ "$HEAD_REF" != "$CI_BUILD_REF" ]; then
  echo "Your revision is not a head of origin/$CI_BUILD_REF_NAME."
  echo "The current head is: $HEAD_REF."
  echo ""
  echo "To speed up testing, we are intentionally failing this build because there is a more recent commit for this branch."
  echo "This failure does not indicate a problem with this commit."
  exit 1
fi
