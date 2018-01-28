function schema_changed() {
  if [[ ! -z `git diff --name-only -- db/schema.rb` ]]; then
    echo "db/schema.rb after rake db:migrate:reset is different from one in the repository"
    exit 1
  else
    echo "db/schema.rb after rake db:migrate:reset matches one in the repository"
  fi
}

schema_changed
