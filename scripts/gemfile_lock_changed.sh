#!/bin/sh

gemfile_lock_changed() {
  if [ -n "$(git diff --name-only -- Gemfile.lock)" ]; then
    cat <<EOF
  Gemfile was updated but Gemfile.lock was not updated.

  Usually, when Gemfile is updated, you should run
  \`\`\`
  bundle install
  \`\`\`

  or

  \`\`\`
  bundle update <the-added-or-updated-gem>
  \`\`\`

  and commit the Gemfile.lock changes.
EOF

    exit 1
  fi
}

gemfile_lock_changed
