# Create update guides

1. Create: CE update guide from previous version. Like `7.3-to-7.4.md`
1. Create: CE to EE update guide in EE repository for latest version.
1. Update: `6.x-or-7.x-to-7.x.md` to latest version.
1. Create: CI update guide from previous version

It's best to copy paste the previous guide and make changes where necessary.
The typical steps are listed below with any points you should specifically look at.

#### 0. Any major changes?

List any major changes here, so the user is aware of them before starting to upgrade. For instance:

- Database updates
- Web server changes
- File structure changes

#### 1. Stop server

#### 2. Make backup

#### 3. Do users need to update dependencies like `git`?

- Check if the [GitLab Shell version](/lib/tasks/gitlab/check.rake#L782) changed since the last release.

- Check if the [Git version](/lib/tasks/gitlab/check.rake#L794) changed since the last release.

#### 4. Get latest code

#### 5. Does GitLab shell need to be updated?

#### 6. Install libs, migrations, etc.

#### 7. Any config files updated since last release?

Check if any of these changed since last release:

- [lib/support/nginx/gitlab](/lib/support/nginx/gitlab)
- [lib/support/nginx/gitlab-ssl](/lib/support/nginx/gitlab-ssl)
- <https://gitlab.com/gitlab-org/gitlab-shell/commits/master/config.yml.example>
- [config/gitlab.yml.example](/config/gitlab.yml.example)
- [config/unicorn.rb.example](/config/unicorn.rb.example)
- [config/database.yml.mysql](/config/database.yml.mysql)
- [config/database.yml.postgresql](/config/database.yml.postgresql)
- [config/initializers/rack_attack.rb.example](/config/initializers/rack_attack.rb.example)
- [config/resque.yml.example](/config/resque.yml.example)

#### 8. Need to update init script?

Check if the `init.d/gitlab` script changed since last release: [lib/support/init.d/gitlab](/lib/support/init.d/gitlab)

#### 9. Start application

#### 10. Check application status
