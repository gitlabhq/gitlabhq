---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: howto, reference
---

# Edit files through the command line **(FREE)**

When [working with Git from the command line](start-using-git.md), you need to
use more than just the Git commands. There are several basic commands that you should
learn, in order to make full use of the command line.

## Start working on your project

To work on a Git project locally (from your own computer), with the command line,
first you need to [clone (copy) it](start-using-git.md#clone-a-repository) to
your computer.

## Working with files on the command line

This section has examples of some basic shell commands that you might find useful.
For more information, search the web for _bash commands_.

Alternatively, you can edit files using your choice of editor (IDE), or the GitLab user
interface (not locally).

### Common commands

The list below is not exhaustive, but contains many of the most commonly used commands.

| Command                        | Description                                 |
|--------------------------------|---------------------------------------------|
| `cd NAME-OF-DIRECTORY`         | Go into a directory to work in it           |
| `cd ..`                        | Go back one directory                       |
| `ls`                           | List what's in the current directory        |
| `ls a*`                        | List what's in the current directory that starts with `a` |
| `ls *.md`                      | List what's in the current directory that ends with `.md` |
| `mkdir NAME-OF-YOUR-DIRECTORY` | Create a new directory                      |
| `cat README.md`                | Display the contents of a [text file you created previously](#create-a-text-file-in-the-current-directory) |
| `pwd`                          | Show the current directory                  |
| `clear`                        | Clear the shell window                      |

### Create a text file in the current directory

To create a text file from the command line, for example `README.md`, follow these
steps:

```shell
touch README.md
nano README.md
#### ADD YOUR INFORMATION
#### Press: control + X
#### Type: Y
#### Press: enter
```

### Remove a file or directory

It's easy to delete (remove) a file or directory, but be careful:

WARNING:
This will **permanently** delete a file.

```shell
rm NAME-OF-FILE
```

WARNING:
This will **permanently** delete a directory and **all** of its contents.

```shell
rm -r NAME-OF-DIRECTORY
```

### View and Execute commands from history

You can view the history of all the commands you executed from the command line,
and then execute any of them again, if needed.

First, list the commands you executed previously:

```shell
history
```

Then, choose a command from the list and check the number next to the command (`123`,
for example) . Execute the same full command with:

```shell
!123
```

### Carry out commands for which the account you are using lacks authority

Not all commands can be executed from a basic user account on a computer, you may
need administrator's rights to execute commands that affect the system, or try to access
protected data, for example. You can use `sudo` to execute these commands, but you
might be asked for an administrator password.

```shell
sudo RESTRICTED-COMMAND
```

WARNING:
Be careful of the commands you run with `sudo`. Certain commands may cause
damage to your data or system.

## Sample Git task flow

If you're completely new to Git, looking through some [sample task flows](https://rogerdudler.github.io/git-guide/)
may help you understand the best practices for using these commands as you work.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
