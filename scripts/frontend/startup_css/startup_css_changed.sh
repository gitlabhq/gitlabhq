#!/bin/sh

echo "-----------------------------------------------------------"
echo "If you run into any issues with Startup CSS generation"
echo "please check out the feedback issue:"
echo ""
echo "https://gitlab.com/gitlab-org/gitlab/-/issues/331812"
echo "-----------------------------------------------------------"

startup_glob="*stylesheets/startup*"

echo "Staging changes to '${startup_glob}' so we can check for untracked files..."
git add "${startup_glob}"

if [ -n "$(git diff HEAD --name-only -- "${startup_glob}")" ]; then
  diff=$(git diff HEAD -- "${startup_glob}")
  cat <<EOF

Startup CSS changes detected!

It looks like there have been recent changes which require
regenerating the Startup CSS files.

IMPORTANT:

  - If you are making changes to any Startup CSS file, it is very likely that
    **both** the CE and EE Startup CSS files will need to be updated.
  - Changing any Startup CSS file will trigger the "as-if-foss" job to also run.

HOW TO FIX:

To fix this job, consider one of the following options:

  1. (Strongly recommended) Copy and apply the diff below:
  2. Regenerate locally with "yarn run generate:startup_css".
     You may need to set "FOSS_ONLY=1" if you are trying to generate for CE.

----- start diff -----
$diff

----- end diff -------
EOF

  exit 1
fi
