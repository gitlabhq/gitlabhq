#!/bin/sh

output=`git ls-files -z | grep -zvE '\.(rb|js|haml)$' | xargs -0n1 grep -HEn '^<<<<<<< '`
echo $output
test -z "$output"
