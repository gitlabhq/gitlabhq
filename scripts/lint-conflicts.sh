#!/bin/sh

output=$(git grep -En '^<<<<<<< ')
echo $output
test -z "$output"
