
# Configure git

Git reads configuration files from three places: first the system config,
then the user's global config and lastly a project config.
Each time the next level config file is read
Git will override any values creating an easy to use cascading configuration system.

## Configuring your global Git identity

The system Git configuration has default values for most options,
the only thing that is missing for a newly installed Git client is your global Git identity.
Git will sign your work (commits) with your identity
so others know who made the changes (or who to blame).
To set your identity open a Terminal and enter in the following commands with your name and email:  

```bash
git config --global user.name "Your Name"
git config --global user.email your@email.com

```

## Listing your Git configuration

To view your git configuration and the file the configuration value came from
enter the following command into a Terminal:

```bash
git config --list --show-origin
```

## Configuring Git line endings

Different operating systems use different characters to indicate the end of a line in text files.  
When working with users of multiple operating systems,
each person's text editor will convert to the operating system or text editor configured line ending.
This will cause each person's changes to appear more substantial than they are
and create an untidy and unauditable Git history.
To overcome this it is recommended to configure Git to convert the line endings.
To use Unix line endings enter the following command:

```bash
git config --global core.autocrlf input
```

## Configure Git per repository

Sometimes you need to override global Git configuration for a repository.
For example if you want to use a different Git identity than your global identity.
To do this you run the following commands in a Terminal with your name and email:

```bash
cd myproject/
git config user.name "Your Name"
git config user.email your@email.com
```

The only differences between the local and global configuration
is that you need to be in the repository folder and you don't need to specify `--global`.
