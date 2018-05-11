retry() {
    if eval "$@"; then
        return 0
    fi

    for i in 2 1; do
        sleep 3s
        echo "Retrying $i..."
        if eval "$@"; then
            return 0
        fi
    done
    return 1
}

setup_db() {
    bundle exec rake db:drop db:create db:schema:load db:migrate

    if [ "$GITLAB_DATABASE" = "mysql" ]; then
        bundle exec rake add_limits_mysql
    fi

    # EE-only
    bundle exec rake geo:db:drop geo:db:create geo:db:schema:load geo:db:migrate
}
