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

setup_db_user_only() {
    if [ "$GITLAB_DATABASE" = "postgresql" ]; then
        . scripts/create_postgres_user.sh
    else
        . scripts/create_mysql_user.sh
    fi
}

setup_db() {
    setup_db_user_only

    bundle exec rake db:drop db:create db:schema:load db:migrate

    if [ "$GITLAB_DATABASE" = "mysql" ]; then
        bundle exec rake add_limits_mysql
    fi
}
