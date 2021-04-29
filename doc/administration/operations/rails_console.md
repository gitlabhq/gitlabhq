---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Rails console **(FREE SELF)**

The [Rails console](https://guides.rubyonrails.org/command_line.html#rails-console).
provides a way to interact with your GitLab instance from the command line.

WARNING:
The Rails console interacts directly with GitLab. In many cases,
there are no handrails to prevent you from permanently modifying, corrupting
or destroying production data. If you would like to explore the Rails console
with no consequences, you are strongly advised to do so in a test environment.

The Rails console is for GitLab system administrators who are troubleshooting
a problem or need to retrieve some data that can only be done through direct
access of the GitLab application.

## Starting a Rails console session

**For Omnibus installations**

```shell
sudo gitlab-rails console
```

**For installations from source**

```shell
sudo -u git -H bundle exec rails console -e production
```

**For Kubernetes deployments**

The console is in the task-runner pod. Refer to our [Kubernetes cheat sheet](../troubleshooting/kubernetes_cheat_sheet.md#gitlab-specific-kubernetes-information) for details.

To exit the console, type: `quit`.

## Output Rails console session history

Enter the following command on the rails console to display
your command history.

```ruby
puts Readline::HISTORY.to_a
```

You can then copy it to your clipboard and save for future reference.

## Using the Rails Runner

If you need to run some Ruby code in the context of your GitLab production
environment, you can do so using the [Rails Runner](https://guides.rubyonrails.org/command_line.html#rails-runner).
When executing a script file, the script must be accessible by the `git` user.

When the command or script completes, the Rails Runner process finishes.
It is useful for running within other scripts or cron jobs for example.

**For Omnibus installations**

```shell
sudo gitlab-rails runner "RAILS_COMMAND"

# Example with a two-line Ruby script
sudo gitlab-rails runner "user = User.first; puts user.username"

# Example with a ruby script file (make sure to use the full path)
sudo gitlab-rails runner /path/to/script.rb
```

**For installations from source**

```shell
sudo -u git -H bundle exec rails runner -e production "RAILS_COMMAND"

# Example with a two-line Ruby script
sudo -u git -H bundle exec rails runner -e production "user = User.first; puts user.username"

# Example with a ruby script file (make sure to use the full path)
sudo -u git -H bundle exec rails runner -e production /path/to/script.rb
```

Rails Runner does not produce the same output as the console.

If you set a variable on the console, the console will generate useful debug output
such as the variable contents or properties of referenced entity:

```ruby
irb(main):001:0> user = User.first
=> #<User id:1 @root>
```

Rails Runner does not do this: you have to be explicit about generating
output:

```shell
$ sudo gitlab-rails runner "user = User.first"
$ sudo gitlab-rails runner "user = User.first; puts user.username ; puts user.id"
root
1
```

Some basic knowledge of Ruby will be very useful. Try [this
30-minute tutorial](https://try.ruby-lang.org/) for a quick introduction.
Rails experience is helpful but not essential.

### Troubleshooting Rails Runner

The `gitlab-rails` command executes Rails Runner using a non-root account and group, by default: `git:git`.

If the non-root account cannot find the Ruby script filename passed to `gitlab-rails runner`
you may get a syntax error, not an error that the file couldn't be accessed.

A common reason for this is that the script has been put in the root account's home directory.

`runner` tries to parse the path and file parameter as Ruby code.

For example:

```plaintext
[root ~]# echo 'puts "hello world"' > ./helloworld.rb
[root ~]# sudo gitlab-rails runner ./helloworld.rb
Please specify a valid ruby command or the path of a script to run.
Run 'rails runner -h' for help.

/opt/gitlab/..../runner_command.rb:45: syntax error, unexpected '.'
./helloworld.rb
^
[root ~]# sudo gitlab-rails runner /root/helloworld.rb
Please specify a valid ruby command or the path of a script to run.
Run 'rails runner -h' for help.

/opt/gitlab/..../runner_command.rb:45: unknown regexp options - hllwrld
[root ~]# mv ~/helloworld.rb /tmp
[root ~]# sudo gitlab-rails runner /tmp/helloworld.rb
hello world
```

A meaningful error should be generated if the directory can be accessed, but the file cannot:

```plaintext
[root ~]# chmod 400 /tmp/helloworld.rb
[root ~]# sudo gitlab-rails runner /tmp/helloworld.rb
Traceback (most recent call last):
      [traceback removed]
/opt/gitlab/..../runner_command.rb:42:in `load': cannot load such file -- /tmp/helloworld.rb (LoadError)
```

In case you encounter a similar error to this:

```plaintext
[root ~]# sudo gitlab-rails runner helloworld.rb
Please specify a valid ruby command or the path of a script to run.
Run 'rails runner -h' for help.

undefined local variable or method `helloworld' for main:Object
```

You can either move the file to the `/tmp` directory or create a new directory owned by the user `git` and save the script in that directory as illustrated below:

```shell
sudo mkdir /scripts
sudo mv /script_path/helloworld.rb /scripts
sudo chown -R git:git /scripts
sudo chmod 700 /scripts
sudo gitlab-rails runner /scripts/helloworld.rb
```
