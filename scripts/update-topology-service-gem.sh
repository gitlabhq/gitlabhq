#!/usr/bin/env bash
set -eo pipefail
## Run this script at the root of the GitLab Rails app

repo=https://gitlab.com/gitlab-org/cells/topology-service.git
ref=${REF:-main}
tmp=tmp/gitlab-topology-service-client
gem_source="$tmp/clients/ruby"
gem_target="vendor/gems/gitlab-topology-service-client"
files_list="$gem_source/.sync"

## Check if there are uncommitted changes
if git diff --exit-code; then
  echo "Clean repo"
else
  echo "There are uncommitted changes. Please commit them and then run this command"
  exit 1
fi

# Cloning the Topology Service Repo into a temporary directory
rm -rf "$tmp"
git clone --single-branch --branch "$ref" "$repo" "$tmp"
echo "Checked out ${ref}"

if [[ -f $files_list ]]; then
   echo "List of files to sync exists. Proceeding"
else
   echo "The checkout out revision doesn't contain a list of files to sync in path: clients/ruby/.sync"
   exit 1
fi

prev_rev=$(cat "$gem_target/REVISION")
rev=$(git -C "$tmp" rev-parse HEAD)
short_rev=$(git -C "$tmp" rev-parse --short HEAD)

## Synchronize (create/update/delete) files
rsync -arv --delete --files-from="$files_list" "$gem_source" "$gem_target"

## Commit Changes
git add $gem_target
if git diff --exit-code HEAD $gem_target; then
  echo "No changes to commit"
else
  echo "Committing code"
  echo "$rev" > "$gem_target/REVISION"
  git add "$gem_target/REVISION"
  changelog=$(git -C "$tmp" log --no-merges --pretty="- %h: %s" "$prev_rev..$rev" -- clients/ruby/)
  git commit -m "Updating Topology Service Client Gem to $short_rev" -m "$changelog" -m 'Changelog: other'
fi

rm -rf "$tmp"
