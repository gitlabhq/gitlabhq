# Command Line basic commands

## Start working on your project

In Git, when you copy a project you say you "clone" it. To work on a git project locally (from your own computer), you will need to clone it. To do this, sign in to GitLab.

When you are on your Dashboard, click on the project that you'd like to clone.
To work in the project, you can copy a link to the Git repository through a SSH
or a HTTPS protocol. SSH is easier to use after it's been
[set up](create-your-ssh-keys.md). While you are at the **Project** tab, select
HTTPS or SSH from the dropdown menu and copy the link using the _Copy URL to clipboard_
button (you'll have to paste it on your shell in the next step).

![Copy the HTTPS or SSH](img/project_clone_url.png)

## Working with project files on the command line

This section has examples of some basic shell commands that you might find useful. For more information, search the web for _bash commands_.

Alternatively, you can edit files using your choice of editor (IDE) or the GitLab user interface.

### Clone your project

Go to your computer's shell and type the following command with your SSH or HTTPS URL:

```
git clone PASTE HTTPS OR SSH HERE
```

A clone of the project will be created in your computer.

NOTE: **Note:**
If you clone your project via a URL that contains special characters, make sure
that characters are URL-encoded.

### Go into a project directory to work in it

```
cd NAME-OF-PROJECT
```

### Go back one directory

```
cd ..
```

### List what’s in the current directory

```
ls
```

### List what’s in the current directory that starts with `a`

```
ls a*
```

### List what’s in the current directory that ends with `.md`

```
ls *.md
```

### Create a new directory

```
mkdir NAME-OF-YOUR-DIRECTORY
```

### Create a README.md file in the current directory

```
touch README.md
nano README.md
#### ADD YOUR INFORMATION
#### Press: control + X
#### Type: Y
#### Press: enter
```

### Show the contents of the README.md file

```
cat README.md
```

### Remove a file

DANGER: **Danger:**
This will permanently delete the file.

```
rm NAME-OF-FILE
```

### Remove a directory and all of its contents

DANGER: **Danger:**
This will permanently delete the directory and all of its contents.

```
rm -r NAME-OF-DIRECTORY
```

### View command history

```
history
```

### Execute command 123 from history

```
!123
```

### Carry out commands for which the account you are using lacks authority

You will be asked for an administrator’s password.

```
sudo COMMAND
```

CAUTION: **Caution:**
Be careful of the commands you run with `sudo`. Certain commands may cause
damage to your data and system.

### Show which directory I am in

```
pwd
```

### Clear the shell window

```
clear
```

### Sample Git taskflow

If you are completely new to Git, looking through some [sample taskflows](https://rogerdudler.github.io/git-guide/) will help you understand best practices for using these commands as you work.
