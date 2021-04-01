---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Guidelines for shell commands in the GitLab codebase

This document contains guidelines for working with processes and files in the GitLab codebase.
These guidelines are meant to make your code more reliable _and_ secure.

## References

- [Google Ruby Security Reviewer's Guide](https://code.google.com/archive/p/ruby-security/wikis/Guide.wiki)
- [OWASP Command Injection](https://wiki.owasp.org/index.php/Command_Injection)
- [Ruby on Rails Security Guide Command Line Injection](https://guides.rubyonrails.org/security.html#command-line-injection)

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

# Sometimes a shell command is just the best solution. The example below has no
# user input, and is hard to implement correctly in Ruby: delete all files and
# directories older than 120 minutes under /some/path, but not /some/path
# itself.
Gitlab::Popen.popen(%W(find /some/path -not -path /some/path -mmin +120 -delete))
```

This coding style could have prevented CVE-2013-4490.

## Always use the configurable Git binary path for Git commands

```ruby
# Wrong
system(*%W(git branch -d -- #{branch_name}))

# Correct
system(*%W(#{Gitlab.config.git.bin_path} branch -d -- #{branch_name}))
```

## Bypass the shell by splitting commands into separate tokens

When we pass shell commands as a single string to Ruby, Ruby lets `/bin/sh` evaluate the entire string. Essentially, we are asking the shell to evaluate a one-line script. This creates a risk for shell injection attacks. It is better to split the shell command into tokens ourselves. Sometimes we use the scripting capabilities of the shell to change the working directory or set environment variables. All of this can also be achieved securely straight from Ruby

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

```shell
# Example
$ echo hello > -l
$ cat -l

cat: illegal option -- l
usage: cat [-benstuv] [file ...]
```

In the example above, the argument parser of `cat` assumes that `-l` is an option. The solution in the example above is to make it clear to `cat` that `-l` is really an argument, not an option. Many Unix command line tools follow the convention of separating options from arguments with `--`.

```shell
# Example (continued)
$ cat -- -l

hello
```

In the GitLab codebase, we avoid the option/argument ambiguity by _always_ using `--` for commands that support it.

```ruby
# Wrong
system(*%W(#{Gitlab.config.git.bin_path} branch -d #{branch_name}))
# Correct
system(*%W(#{Gitlab.config.git.bin_path} branch -d -- #{branch_name}))
```

This coding style could have prevented CVE-2013-4582.

## Do not use the backticks

Capturing the output of shell commands with backticks reads nicely, but you are forced to pass the command as one string to the shell. We explained above that this is unsafe. In the main GitLab codebase, the solution is to use `Gitlab::Popen.popen` instead.

```ruby
# Wrong
logs = `cd #{repo_dir} && #{Gitlab.config.git.bin_path} log`
# Correct
logs, exit_status = Gitlab::Popen.popen(%W(#{Gitlab.config.git.bin_path} log), repo_dir)

# Wrong
user = `whoami`
# Correct
user, exit_status = Gitlab::Popen.popen(%W(whoami))
```

In other repositories, such as GitLab Shell you can also use `IO.popen`.

```ruby
# Safe IO.popen example
logs = IO.popen(%W(#{Gitlab.config.git.bin_path} log), chdir: repo_dir) { |p| p.read }
```

Note that unlike `Gitlab::Popen.popen`, `IO.popen` does not capture standard error.

## Avoid user input at the start of path strings

Various methods for opening and reading files in Ruby can be used to read the
standard output of a process instead of a file. The following two commands do
roughly the same:

```ruby
`touch /tmp/pawned-by-backticks`
File.read('|touch /tmp/pawned-by-file-read')
```

The key is to open a 'file' whose name starts with a `|`.
Affected methods include Kernel#open, File::read, File::open, IO::open and IO::read.

You can protect against this behavior of 'open' and 'read' by ensuring that an
attacker cannot control the start of the filename string you are opening. For
instance, the following is sufficient to protect against accidentally starting
a shell command with `|`:

```ruby
# we assume repo_path is not controlled by the attacker (user)
path = File.join(repo_path, user_input)
# path cannot start with '|' now.
File.read(path)
```

If you have to use user input a relative path, prefix `./` to the path.

Prefixing user-supplied paths also offers extra protection against paths
starting with `-` (see the discussion about using `--` above).

## Guard against path traversal

Path traversal is a security where the program (GitLab) tries to restrict user
access to a certain directory on disk, but the user manages to open a file
outside that directory by taking advantage of the `../` path notation.

```ruby
# Suppose the user gave us a path and they are trying to trick us
user_input = '../other-repo.git/other-file'

# We look up the repo path somewhere
repo_path = 'repositories/user-repo.git'

# The intention of the code below is to open a file under repo_path, but
# because the user used '..' they can 'break out' into
# 'repositories/other-repo.git'
full_path = File.join(repo_path, user_input)
File.open(full_path) do # Oops!
```

A good way to protect against this is to compare the full path with its
'absolute path' according to Ruby's `File.absolute_path`.

```ruby
full_path = File.join(repo_path, user_input)
if full_path != File.absolute_path(full_path)
  raise "Invalid path: #{full_path.inspect}"
end

File.open(full_path) do # Etc.
```

A check like this could have avoided CVE-2013-4583.

## Properly anchor regular expressions to the start and end of strings

When using regular expressions to validate user input that is passed as an argument to a shell command, make sure to use the `\A` and `\z` anchors that designate the start and end of the string, rather than `^` and `$`, or no anchors at all.

If you don't, an attacker could use this to execute commands with potentially harmful effect.

For example, when a project's `import_url` is validated like below, the user could trick GitLab into cloning from a Git repository on the local file system.

```ruby
validates :import_url, format: { with: URI.regexp(%w(ssh git http https)) }
# URI.regexp(%w(ssh git http https)) roughly evaluates to /(ssh|git|http|https):(something_that_looks_like_a_url)/
```

Suppose the user submits the following as their import URL:

```plaintext
file://git:/tmp/lol
```

Since there are no anchors in the used regular expression, the `git:/tmp/lol` in the value would match, and the validation would pass.

When importing, GitLab would execute the following command, passing the `import_url` as an argument:

```shell
git clone file://git:/tmp/lol
```

Git ignores the `git:` part, interpret the path as `file:///tmp/lol`, and imports the repository into the new project. This action could potentially give the attacker access to any repository in the system, whether private or not.
