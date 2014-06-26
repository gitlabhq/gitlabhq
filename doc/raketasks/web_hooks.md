# Web hooks

## Add a web hook for **ALL** projects:

    # omnibus-gitlab
    sudo gitlab-rake gitlab:web_hook:add URL="http://example.com/hook"
    # source installations or cookbook
    RAILS_ENV=production bundle exec rake gitlab:web_hook:add URL="http://example.com/hook"

## Add a web hook for projects in a given **NAMESPACE**:

    # omnibus-gitlab
    sudo gitlab-rake gitlab:web_hook:add URL="http://example.com/hook" NAMESPACE=acme
    # source installations or cookbook
    RAILS_ENV=production bundle exec rake gitlab:web_hook:add URL="http://example.com/hook" NAMESPACE=acme

## Remove a web hook from **ALL** projects using:

    # omnibus-gitlab
    sudo gitlab-rake gitlab:web_hook:rm URL="http://example.com/hook"
    # source installations or cookbook
    RAILS_ENV=production bundle exec rake gitlab:web_hook:rm URL="http://example.com/hook"

## Remove a web hook from projects in a given **NAMESPACE**:

    # omnibus-gitlab
    sudo gitlab-rake gitlab:web_hook:rm URL="http://example.com/hook" NAMESPACE=acme
    # source installations or cookbook
    RAILS_ENV=production bundle exec rake gitlab:web_hook:rm URL="http://example.com/hook" NAMESPACE=acme

## List **ALL** web hooks:

    # omnibus-gitlab
    sudo gitlab-rake gitlab:web_hook:list
    # source installations or cookbook
    RAILS_ENV=production bundle exec rake gitlab:web_hook:list

## List the web hooks from projects in a given **NAMESPACE**:

    # omnibus-gitlab
    sudo gitlab-rake gitlab:web_hook:list NAMESPACE=/
    # source installations or cookbook
    RAILS_ENV=production bundle exec rake gitlab:web_hook:list NAMESPACE=/

> Note: `/` is the global namespace.
