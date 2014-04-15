# Adding deploy keys to multiple projects

If you want to easily add the same deploy key to multiple projects in the same group, this can be achieved quite easily with the API.

First, find the ID of the projects you're interested in, by either listing all projects:

```
curl https://gitlab.com/api/v3/projects?private_token=abcdef
```

Or finding the id of a group and then listing all projects in that group:

```
curl https://gitlab.com/api/v3/groups?private_token=abcdef

curl https://gitlab.com/api/v3/groups/1234?private_token=abcdef # where the id of the group is 1234
```

With those IDs, add the same deploy key to all:
```
curl -X POST curl https://gitlab.com/api/v3/projects/321/deploy_key_here?private_token=abcdef
```
