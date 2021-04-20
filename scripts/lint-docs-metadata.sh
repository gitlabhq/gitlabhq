#!/usr/bin/env bash

# Used in `lefthook.yml`
(( counter=0 ))

for file in $1
do
  if [ "$(head -n1 "$file")" != "---" ]
  then
    printf "%sDocumentation metadata missing in %s%s\n" "$(tput setaf 1)" "$file" "$(tput sgr0)"
    (( counter++ ))
  else
    printf "Documentation metadata found in %s.\n" "$file"
  fi
done

if [ "$counter" -gt 0 ]
then
  printf "\n%sDocumentation metadata is missing in changed documentation files.%s For more information, see https://docs.gitlab.com/ee/development/documentation/#metadata.\n" "$(tput setaf 1)" "$(tput sgr0)"
  false
else
  printf "\n%sDocumentation metadata found in all changed documentation files.%s\n" "$(tput setaf 2)" "$(tput sgr0)"
  true
fi
