# Adding deploy keys to multiple projects

If you want to easily add the same deploy key to multiple projects in the same group, this can be achieved quite easily with the API.

First, find the ID of the projects you're interested in, by either listing all projects:

```
curl --header 'PRIVATE-TOKEN: abcdef' https://gitlab.com/api/v3/projects
```

Or finding the id of a group and then listing all projects in that group:

```
curl --header 'PRIVATE-TOKEN: abcdef' https://gitlab.com/api/v3/groups

# For group 1234:
curl --header 'PRIVATE-TOKEN: abcdef' https://gitlab.com/api/v3/groups/1234
```

With those IDs, add the same deploy key to all:
```
for project_id in 321 456 987; do
    curl -X POST --data '{"title": "my key", "key": "ssh-rsa AAAA..."}' --header 'PRIVATE-TOKEN: abcdef' https://gitlab.com/api/v3/projects/${project_id}/keys
done
```
