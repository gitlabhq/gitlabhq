# Guidelines for shell commands in the GitLab codebase

## References

- [Google Ruby Security Reviewer's Guide](https://code.google.com/p/ruby-security/wiki/Guide)
- [OWASP Command Injection](https://www.owasp.org/index.php/Command_Injection)
- [Ruby on Rails Security Guide Command Line Injection](http://guides.rubyonrails.org/security.html#command-line-injection)

## Use File and FileUtils instead of shell commands

Sometimes we invoke basic Unix commands via the shell when there is also a Ruby API for doing it. Use the Ruby API if it exists. <http://www.ruby-doc.org/stdlib-2.0.0/libdoc/fileutils/rdoc/FileUtils.html#module-FileUtils-label-Module+Functions>

```ruby
# Wrong
system "mkdir -p tmp/special/directory"
# Better (separate tokens)
system *%W(mkdir -p tmp/special/directory)
# Best (do not use a shell command)
FileUtils.mkdir_p "tmp/special/directory"

# Wrong
contents = `cat #{filename}`
# Correct
contents = File.read(filename)
```

This coding style could have prevented CVE-2013-4490.

## Bypass the shell by splitting commands into separate tokens

When we pass shell commands as a single string to Ruby, Ruby will let `/bin/sh` evaluate the entire string. Essentially, we are asking the shell to evaluate a one-line script. This creates a risk for shell injection attacks. It is better to split the shell command into tokens ourselves. Sometimes we use the scripting capabilities of the shell to change the working directory or set environment variables. All of this can also be achieved securely straight from Ruby

```ruby
# Wrong
system "cd /home/git/gitlab && bundle exec rake db:#{something} RAILS_ENV=production"
# Correct
system({'RAILS_ENV' => 'production'}, *%W(bundle exec rake db:#{something}), chdir: '/home/git/gitlab')

# Wrong
system "touch #{myfile}"
# Better
system "touch", myfile
# Best (do not run a shell command at all)
FileUtils.touch myfile
```

This coding style could have prevented CVE-2013-4546.

## Separate options from arguments with --

Make the difference between options and arguments clear to the argument parsers of system commands with `--`. This is supported by many but not all Unix commands.

To understand what `--` does, consider the problem below.

```
# Example
$ echo hello > -l
$ cat -l
cat: illegal option -- l
usage: cat [-benstuv] [file ...]
```

In the example above, the argument parser of `cat` assumes that `-l` is an option. The solution in the example above is to make it clear to `cat` that `-l` is really an argument, not an option. Many Unix command line tools follow the convention of separating options from arguments with `--`.

```
# Example (continued)
$ cat -- -l
hello
```

In the GitLab codebase, we avoid the option/argument ambiguity by _always_ using `--`.

```ruby
# Wrong
system(*%W(git branch -d #{branch_name}))
# Correct
system(*%W(git branch -d -- #{branch_name}))
```

This coding style could have prevented CVE-2013-4582.

## Do not use the backticks

Capturing the output of shell commands with backticks reads nicely, but you are forced to pass the command as one string to the shell. We explained above that this is unsafe. In the main GitLab codebase, the solution is to use `Gitlab::Popen.popen` instead.

```ruby
# Wrong
logs = `cd #{repo_dir} && git log`
# Correct
logs, exit_status = Gitlab::Popen.popen(%W(git log), repo_dir)

# Wrong
user = `whoami`
# Correct
user, exit_status = Gitlab::Popen.popen(%W(whoami))
```

In other repositories, such as gitlab-shell you can also use `IO.popen`.

```ruby
# Safe IO.popen example
logs = IO.popen(%W(git log), chdir: repo_dir).read
```

Note that unlike `Gitlab::Popen.popen`, `IO.popen` does not capture standard error.
