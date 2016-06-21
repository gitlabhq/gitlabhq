# Migrating from SVN to GitLab

Subversion (SVN) is a central version control system (VCS) while
Git is a distributed version control system. There are some major differences
between the two, for more information consult your favorite search engine.

If you are currently using an SVN repository, you can migrate the repository
to Git and GitLab. We recommend a hard cut over - run the migration command once
and then have all developers start using the new GitLab repository immediately.
Otherwise, it's hard to keep changing in sync in both directions. The conversion
process should be run on a local workstation.

Install `svn2git`. On all systems you can install as a Ruby gem if you already
have Ruby and Git installed.

```bash
sudo gem install svn2git
```

On Debian-based Linux distributions you can install the native packages:

```bash
sudo apt-get install git-core git-svn ruby
```

Optionally, prepare an authors file so `svn2git` can map SVN authors to Git authors.
If you choose not to create the authors file then commits will not be attributed
to the correct GitLab user. Some users may not consider this a big issue while
others will want to ensure they complete this step. If you choose to map authors
you will be required to map every author that is present on changes in the SVN
repository. If you don't, the conversion will fail and you will have to update
the author file accordingly. The following command will search through the
repository and output a list of authors.

```bash
svn log --quiet | grep -E "r[0-9]+ \| .+ \|" | cut -d'|' -f2 | sed 's/ //g' | sort | uniq
```

Use the output from the last command to construct the authors file.
Create a file called `authors.txt` and add one mapping per line.

```
janedoe = Jane Doe <janedoe@example.com>
johndoe = John Doe <johndoe@example.com>
```

If your SVN repository is in the standard format (trunk, branches, tags,
not nested) the conversion is simple. For a non-standard repository see
[svn2git documentation](https://github.com/nirvdrum/svn2git). The following
command will checkout the repository and do the conversion in the current
working directory. Be sure to create a new directory for each repository before
running the `svn2git` command. The conversion process will take some time.

```bash
svn2git https://svn.example.com/path/to/repo --authors /path/to/authors.txt
```

If your SVN repository requires a username and password add the
`--username <username>` and `--password <password` flags to the above command.
`svn2git` also supports excluding certain file paths, branches, tags, etc. See
[svn2git documentation](https://github.com/nirvdrum/svn2git) or run
`svn2git --help` for full documentation on all of the available options.

Create a new GitLab project, where you will eventually push your converted code.
Copy the SSH or HTTP(S) repository URL from the project page. Add the GitLab
repository as a Git remote and push all the changes. This will push all commits,
branches and tags.

```bash
git remote add origin git@gitlab.com:<group>/<project>.git
git push --all origin
git push --tags origin
```

## Contribute to this guide
We welcome all contributions that would expand this guide with instructions on
how to migrate from SVN and other version control systems.


