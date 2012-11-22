#!/bin/bash

src="/home/git/repositories"

for dir in `ls "$src/"`
do
  if [ -d "$src/$dir" ]; then

    if [ "$dir" = "gitolite-admin.git" ]
    then
      continue 
    fi

    project_hook="$src/$dir/hooks/post-receive"
    gitolite_hook="/home/git/.gitolite/hooks/common/post-receive"

    ln -s -f $gitolite_hook $project_hook
  fi
done
