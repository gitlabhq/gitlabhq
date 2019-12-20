#!/bin/sh

output=`git grep -En '^<<<<<<< ' -- . ':(exclude)spec/lib/gitlab/conflict/file_spec.rb' ':(exclude)spec/lib/gitlab/git/conflict/parser_spec.rb'`
echo $output
test -z "$output"
