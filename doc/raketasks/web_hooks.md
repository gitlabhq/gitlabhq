# Web hooks

### Add a web hook for **ALL** projects:

    RAILS_ENV=production bundle exec rake gitlab:web_hook:add URL="http://example.com/hook"


### Add a web hook for projects in a given **NAMESPACE**:

    RAILS_ENV=production bundle exec rake gitlab:web_hook:add URL="http://example.com/hook" NAMESPACE=acme


### Remove a web hook from **ALL** projects using:

    RAILS_ENV=production bundle exec rake gitlab:web_hook:rm URL="http://example.com/hook"


### Remove a web hook from projects in a given **NAMESPACE**:

    RAILS_ENV=production bundle exec rake gitlab:web_hook:rm URL="http://example.com/hook" NAMESPACE=acme


### List **ALL** web hooks:

    RAILS_ENV=production bundle exec rake gitlab:web_hook:list


### List the web hooks from projects in a given **NAMESPACE**:

    RAILS_ENV=production bundle exec rake gitlab:web_hook:list NAMESPACE=/

> Note: `/` is the global namespace.

