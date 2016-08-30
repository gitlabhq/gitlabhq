# Adding deploy keys to multiple projects

If you want to easily add the same deploy key to multiple projects in the same
group, this can be achieved quite easily with the API.

First, find the ID of the projects you're interested in, by either listing all
projects:

```
curl --header 'PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK' https://gitlab.example.com/api/v3/projects
```

Or finding the ID of a group and then listing all projects in that group:

```
curl --header 'PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK' https://gitlab.example.com/api/v3/groups

# For group 1234:
curl --header 'PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK' https://gitlab.example.com/api/v3/groups/1234
```

With those IDs, add the same deploy key to all:

```
for project_id in 321 456 987; do
    curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" --header "Content-Type: application/json" \
    --data '{"title": "my key", "key": "ssh-rsa AAAA..."}' https://gitlab.example.com/api/v3/projects/${project_id}/deploy_keys
done
```
