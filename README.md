# Public GitLab

## Presentation

Public GitLab is a fork of the official [GitLab](https://github.com/gitlabhq/gitlabhq) software. This fork allows you to host public repositories as long as official software does NOT support it (e.g. for Open Source projects). With this fork, I'm trying to reproduce Github behaviour.

So by public I mean:

  * Allow anonymous users to browse your public repositories.
  * Allow anonymous users to download your code (not only by `git clone`).
  * Allow anonymous users to register and report issues on public projects.

With these features, GitLab can be a self-hosted Github competitor.

You can browse a live example at http://git.hoa.ro (you won't be able to create projects).

_Disclaimer_: I do not provide any support on GitLab itself.  I only contribute to the _public_ part.  Please refer to the [official documentation](https://github.com/gitlabhq/gitlabhq/blob/master/README.md) for any help on GitLab itself.

You should also be aware that **Public GitLab** only applies to the latest [stable](https://github.com/ArthurHoaro/Public-GitLab/) release branch of GitLab.  So, use the *-stable branches!  The `master` branch on this repo has a high chance to be broken.
## Changelog

  * [2013-08-25] : Public GitLab supports GitLab 6.0 (stable) - [Upgrade 5.4 to 6.0](https://github.com/ArthurHoaro/Public-GitLab/blob/6-0-stable/doc/update/5.4-to-6.0.md)
  
  > Note: Follow [@PGitLab](https://twitter.com/PGitLab) to get news on the project (or [RSS feed here](http://rssbridge.org/b/Twitter/Atom/u/pgitlab/)).

  * [2013-07-29] : Fixes 2 issues (more at #22)
  * [2013-07-24] : Public GitLab supports GitLab 5.4 (stable) - [Upgrade 5.3 to 5.4](https://github.com/ArthurHoaro/Public-GitLab/blob/6-0-stable/doc/update/5.3-to-5.4.md)
  * [2013-07-06] : [New feature](https://github.com/ArthurHoaro/Public-GitLab/pull/19) ! Added a different projects number limit per user for private and public projects. Thanks to [Mike](https://github.com/MJSmith5) for the idea.
  
  > Please update your DB model to use it ( `bundle exec rake db:migrate RAILS_ENV=production` ).
  > Warning: New option in `config/gitlab.yml.example` (`default_projects_limit_private`).
  
  * [2013-06-30] : Public GitLab supports GitLab 5.3 (stable) - [Upgrade 5.2 to 5.3](https://github.com/ArthurHoaro/Public-GitLab/blob/6-0-stable/doc/update/5.2-to-5.3.md)
  * [2013-05-29] : Public GitLab supports GitLab 5.2 (stable) - [Upgrade 5.1 to 5.2](https://github.com/ArthurHoaro/Public-GitLab/blob/6-0-stable/doc/update/5.1-to-5.2.md)
  * [2013-05-03] : Bugfix (you need to [update](https://github.com/ArthurHoaro/Public-GitLab#update-public-gitlab) your DB triggers)
  * [2013-04-25] : Public GitLab supports GitLab 5.1 (stable) - [Upgrade 5.0 to 5.1](https://github.com/ArthurHoaro/Public-GitLab/blob/6-0-stable/doc/update/5.0-to-5.1.md)

> Warning: GitLab 5.1 does not work properly with old version of Git (ok on 1.7.10+). [More here](https://github.com/gitlabhq/gitlabhq/issues/3666). 
  
  * [2013-04-11] : MySQL support
  * [2013-04-01] : First commit for Public GitLab (only PostgreSQL)

## Installation

During the [official installation](https://github.com/gitlabhq/gitlabhq/blob/6-0-stable/doc/install/installation.md) workflow, **Public GitLab** override part _"6. GitLab - Clone the Source"_.

**Warning**: Remember that you _need_ to use the latest **stable branch**, even if you want to download it from [zip file](https://github.com/ArthurHoaro/Public-GitLab/archive/6-0-stable.zip).

> Note: You can also use my [GitLab install scripts](http://git.hoa.ro/arthur/gitlab-install) for CentOS.

### Clone the Source

    # Clone GitLab repository
    sudo -u git -H git clone https://github.com/ArthurHoaro/Public-GitLab.git gitlab

    # Go to gitlab dir
    cd /home/git/gitlab

    # Checkout to stable release
    sudo -u git -H git checkout 6-0-stable

### Post installation
At this point, all of the GitLab components are installed.  You still can't access GitLab though.

The SQL script below creates a default `guest` user for anonymous access.  It also creates a default team (`pgl_reporters`), giving `reporter` permission to all _future_ users for all public projects.

> Note that your DB user needs to have the TRIGGER permission on your database (this is specific to Public GitLab).

#### PostgreSQL
You have to patch your GitLab database with 2 SQL scripts:

    cd /home/git/gitlab/pgl
    psql -h host -U user database < pgl_pgsql_insert.sql
    psql -h host -U user database < pgl_pgsql_trigger.sql

#### MySQL
You have to patch your GitLab database with 2 SQL scripts:

    cd /home/git/gitlab/pgl
    mysql -hhost -uuser -p
    use database
    source pgl_mysql_insert.sql
    source pgl_mysql_trigger.sql

### Allow signup

In the file ~/gitlab/config/gitlab.yml, uncomment:

    signup_enabled: true

Note: Keep in mind that if you do not allow signups, guests won't be able to report issues. 

If you do not want guest users to create projects on your GitLab installation, set `default_projects_limit: 0` in `config/gitlab.yaml`.

### Restart GitLab

Remember to restart GitLab after all these changes :

    sudo /etc/init.d/gitlab restart

Then enjoy !

## Update Public GitLab

You need to refer to official [update guides](https://github.com/ArthurHoaro/Public-GitLab/blob/6-0-stable/doc/update/) to upgrade GitLab version.

If the changelog on this README indicates any SQL update, you need to update your database :

PostgreSQL:

     cd /home/git/gitlab/pgl
     psql -h host -U user database < pgl_pgsql_trigger.sql
     

MySQL:

    cd /home/git/gitlab/pgl
    mysql -hhost -uuser -p
    use database
    source pgl_mysql_trigger.sql


## Reporting issues

See [CONTRIBUTING](https://github.com/ArthurHoaro/Public-GitLab/blob/6-0-stable/CONTRIBUTING.md).

If there is a new stable branch, please do not open an issue to ask for an update.  [Contact me](http://hoa.ro/static6/contact) instead.

## Troubleshooting

### Removing root user

The reporters team created by Public GitLab is owned by the root user (Administrator).  If you delete this user, it will cause problems in your GitLab installation.

If you _really_ need to remove `root`, you need to change the `pgl_reporters` team's owner in GitLab administration before deleting it.

If you have already deleted the root user, you have to manually change Public GitLab SQL `insert` to :

    INSERT INTO user_teams (name, path, owner_id, created_at, updated_at, description) 
    VALUES ('pgl_reporters', 'pgl_reporters', (SELECT id FROM users WHERE username = 'YOU_NEW_ADMIN_USERNAME'), now(), now(), 'Default new users team (reporter permission)'); 

Read more at issues [#3](https://github.com/ArthurHoaro/Public-GitLab/issues/3) and [#4](https://github.com/ArthurHoaro/Public-GitLab/issues/4).

### Styles don't apply properly

I had an issue with styles while upgrading from 5.4 to 6.0, so if it can help, here is what to do :

  * Stop your Public-GitLab instance.
  * Execute :

```
RAILS_ENV=production bundle exec rake assets:clean
RAILS_ENV=production bundle exec rake assets:precompile
```

  * Restart your Public-GitLab instance.

## License

Public GitLab is provided and maintained by [Arthur Hoaro](http://hoa.ro).

Public GitLab is distributed under the [same license](https://github.com/ArthurHoaro/Public-GitLab/blob/6-0-stable/LICENSE) as the original software.

This fork is based on [cjdelisle](https://github.com/cjdelisle/) work, from his [original fork](https://github.com/cjdelisle/gitboria.com/commit/61db393bfd4fc75c5f046f01b01c7f114f601426).
