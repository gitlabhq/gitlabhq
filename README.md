# Public GitLab

## Presentation

Public GitLab is a fork of the official [GitLab](https://github.com/gitlabhq/gitlabhq) software. This fork allows you to host public repositories as long as official software does NOT support it (e.g. for Open Source projects). With this fork, I'm trying to reproduce Github behavior.

So by public I mean:

  * Allow anonymous users to browse your public repositories.
  * Allow anonymous users to download your code (not only by `git clone`).
  * Allow anonymous users to register and report issues on public projects.

With these features, GitLab can be a self-hosted Github competitor.

You can browse a live example at http://git.hoa.ro (you won't be able to create projects).

_Disclaimer_: I do not provide any support on GitLab itself. I only contribute to the _public_ part. Please refer to the [official documentation](https://github.com/gitlabhq/gitlabhq/blob/master/README.md) for any help on GitLab itself.

You should also be aware that **Public GitLab** only applies to the lastest [stable](https://github.com/ArthurHoaro/Public-GitLab/) release branch of GitLab. `master` branch on this repo have high chance to be broken.

## Installation

During the [official intallation](https://github.com/gitlabhq/gitlabhq/blob/5-0-stable/doc/install/installation.md) workflow, **Public GitLab** override part _"6. GitLab - Clone the Source"_. 

**Warning**: Remember that you _need_ to use the lastest **stable branch**, even if you want to dowload it from [zip file](https://github.com/ArthurHoaro/Public-GitLab/archive/5-0-stable.zip).

### Clone the Source

    # Clone GitLab repository
    sudo -u git -H git clone https://github.com/ArthurHoaro/Public-GitLab.git gitlab

    # Go to gitlab dir
    cd /home/git/gitlab

    # Checkout to stable release
    sudo -u git -H git checkout 5-0-stable

### Post installation
At this point, every GitLab components are installed. You still can not access to GitLab yet though.

The SQL script below will create a default `guest` user for anonymous access. It will also create a default team (`pgl_reporters`) which allows `reporter` permission to every new _future_ users, for all public projects.

#### PostgreSQL
You have to patch GitLab your database with `pgl_script_postgres.sql`:

    cd /home/git/gitlab/pgl
    psql -h host -U user database < pgl_script_postgres.sql

#### MySQL
You have to patch GitLab your database with `pgl_script_mysql.sql`:

    cd /home/git/gitlab/pgl
    mysql -hhost -uuser -p
    use database
    source pgl_script_mysql.sql

### Allow signup

In the file ~/gitlab/config/gitlab.yml, uncomment:

    signup_enabled: true

Note: Keep in mind that if you do not allow signup, guest wouldn't be able to report issues. 

If you do not want guest users to create projects on your GitLab installation, set `default_projects_limit: 0` in `config/gitlab.yaml`.

### Restart GitLab

Remember to restart GitLab after all these changes :

    sudo /etc/init.d/gitlab restart

Then enjoy !

## Reporting issues

If you have issues with Public GitLab, you can report them with the [Github issues module](https://github.com/ArthurHoaro/Public-GitLab/issues). 

Please rememberer to tell us which database you are using.

If there is a new stable branch, please do not open an issue to ask update. [Contact me](http://hoa.ro/static6/contact) instead.

## License

Public GitLab is provided and maintain by [Arthur Hoaro](http://hoa.ro).

Public GitLab is distributed under the [same license](https://github.com/ArthurHoaro/Public-GitLab/blob/5-0-stable/LICENSE) as the original sofware.

This fork is based on [cjdelisle](https://github.com/cjdelisle/) work, from his [original fork](https://github.com/cjdelisle/gitboria.com/commit/61db393bfd4fc75c5f046f01b01c7f114f601426).
