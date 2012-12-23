### Enable usernames and namespaces for user projects

This command will enable the namespaces feature introduced in v4.0. It will move every project in its namespace folder.

Note:

* Because the **repository location will change**, you will need to **update all your git url's** to point to the new location.
* Username can be changed at [Profile / Account](/profile/account)

**Example:**

Old path: `git@example.org:myrepo.git`
New path: `git@example.org:username/myrepo.git` or `git@example.org:groupname/myrepo.git`

```
bundle exec rake gitlab:enable_namespaces
```


### Enable auto merge

This command will enable the auto merge feature. After this you will be able to **merge a merge request** via GitLab and use the **online editor**.

```
bundle exec rake gitlab:enable_automerge
```

Example output:

```
Creating satellite for abcd.git
[git clone output]
Creating satellite for abcd2.git
[git clone output]
done
```
