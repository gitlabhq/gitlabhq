#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

if [ ! -d "glfm_specification" ] || [ ! -f "GITALY_SERVER_VERSION" ]; then
  echo 'Please run this from the gitlab root folder with `./scripts/frontend/compare_css_compilers.sh`'
  exit 1
fi

function clean_up {
  rm -rf public/assets
  rm -rf app/assets/builds/*
  rm -rf tmp/cache/assets
}

rm -rf tmp/css_compare
clean_up

export SKIP_YARN_INSTALL=1

echo "Compiling with sassc-rails"
export USE_NEW_CSS_PIPELINE=0
time bin/rails assets:precompile
scripts/frontend/clean_css_assets.mjs public/assets tmp/css_compare/sassc-rails

clean_up

export USE_NEW_CSS_PIPELINE=1
echo "Compiling with dart-sass"
time bin/rails assets:precompile
scripts/frontend/clean_css_assets.mjs public/assets tmp/css_compare/cssbundling

clean_up

echo 'You now can run `diff -u tmp/css_compare/sassc-rails tmp/css_compare/cssbundling` to diff the two'
