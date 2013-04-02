# Public GitLab

## Presentation

Public GitLab is a fork of the official GitLab software. This fork allows you to host public repositories as long as official software does NOT support it (e.g. for Open Source projects).

By public I mean:

  * Allow anonymous users to browse your repository.
  * Allow anonymous users to download your code (not only by `git clone`).
  * Allow anonymous users to register and submit issues.

With these features, GitLab can be a self-hosted Github competitor.

_Disclaimer_: I do not provide any support on GitLab itself. I'm only contribute on the _public_ part. Please refer to the [official documentation](https://github.com/gitlabhq/gitlabhq/blob/master/README.md) for any help on GitLab itself.

You should also be aware that **Public GitLab** only applies to the lastest [`stable`](http://git.hoa.ro/arthur/public-gitlab/tree/5-0-stable/) release branch. `master` branch on this repo have high chance to be broken.

## Installation

During the [official intallation](https://github.com/gitlabhq/gitlabhq/blob/5-0-stable/doc/install/installation.md) workflow, **Public GitLab** override part "_6. GitLab - Clone the Source_". 

### Clone the Source

    # Clone GitLab repository
    sudo -u git -H git clone http://git.hoa.ro/arthur/public-gitlab.git gitlab

    # Go to gitlab dir
    cd /home/git/gitlab

    # Checkout to stable release
    sudo -u git -H git checkout 5-0-stable

### Add guest user

Connect to your database, and execute the following SQL command:

    insert into users (email, encrypted_password, name, username, projects_limit, can_create_team, can_create_group, sign_in_count, created_at, updated_at, admin ) 
    values ('guest@local.host', '$2a$10$ivc.WwouK4tKT3ZtV8kiD.oVZRzJLV0df7K4nJRV73hhf9a92JeJ.', 'guest', 'guest', 0, 'f', 'f', 0, now(), now(), 'f');

### Allow signup 

In the file ~/gitlab/config/gitlab.yml, uncomment:

    signup_enabled: true