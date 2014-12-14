# Web hooks

Project web hooks allow you to trigger an URL if new code is pushed or a new issue is created.

You can configure web hooks to listen for specific events like pushes, issues or merge requests. GitLab will send a POST request with data to the web hook URL.

Web hooks can be used to update an external issue tracker, trigger CI builds, update a backup mirror, or even deploy to your production server.

If you send a web hook to an SSL endpoint [the certificate will not be verified](https://gitlab.com/gitlab-org/gitlab-ce/blob/ccd617e58ea71c42b6b073e692447d0fe3c00be6/app/models/web_hook.rb#L35) since many people use self-signed certificates.

## Push events

Triggered when you push to the repository except when pushing tags.

**Request body:**

```json
{
  "before": "95790bf891e76fee5e1747ab589903a6a1f80f22",
  "after": "da1560886d4f094c3e6c9ef40349f7d38b5d27d7",
  "ref": "refs/heads/master",
  "user_id": 4,
  "user_name": "John Smith",
  "project_id": 15,
  "repository": {
    "name": "Diaspora",
    "url": "git@example.com:diaspora.git",
    "description": "",
    "homepage": "http://example.com/diaspora"
  },
  "commits": [
    {
      "id": "b6568db1bc1dcd7f8b4d5a946b0b91f9dacd7327",
      "message": "Update Catalan translation to e38cb41.",
      "timestamp": "2011-12-12T14:27:31+02:00",
      "url": "http://example.com/diaspora/commits/b6568db1bc1dcd7f8b4d5a946b0b91f9dacd7327",
      "author": {
        "name": "Jordi Mallach",
        "email": "jordi@softcatala.org"
      }
    },
    {
      "id": "da1560886d4f094c3e6c9ef40349f7d38b5d27d7",
      "message": "fixed readme",
      "timestamp": "2012-01-03T23:36:29+02:00",
      "url": "http://example.com/diaspora/commits/da1560886d4f094c3e6c9ef40349f7d38b5d27d7",
      "author": {
        "name": "GitLab dev user",
        "email": "gitlabdev@dv6700.(none)"
      }
    }
  ],
  "total_commits_count": 4
}
```

## Tag events

Triggered when you create (or delete) tags to the repository.

**Request body:**

```json
{
  "ref": "refs/tags/v1.0.0",
  "before": "0000000000000000000000000000000000000000",
  "after": "82b3d5ae55f7080f1e6022629cdb57bfae7cccc7",
  "user_id": 1,
  "user_name": "John Smith",
  "project_id": 1,
  "repository": {
    "name": "jsmith",
    "url": "ssh://git@example.com/jsmith/example.git",
    "description": "",
    "homepage": "http://example.com/jsmith/example"
  }
}
```

## Issues events

Triggered when a new issue is created or an existing issue was updated/closed/reopened.

**Request body:**

```json
{
  "object_kind": "issue",
  "user": {
    "name": "Administrator",
    "username": "root",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=40\u0026d=identicon"
  },
  "object_attributes": {
    "id": 301,
    "title": "New API: create/update/delete file",
    "assignee_id": 51,
    "author_id": 51,
    "project_id": 14,
    "created_at": "2013-12-03T17:15:43Z",
    "updated_at": "2013-12-03T17:15:43Z",
    "position": 0,
    "branch_name": null,
    "description": "Create new API for manipulations with repository",
    "milestone_id": null,
    "state": "opened",
    "iid": 23,
    "url": "http://example.com/diaspora/issues/23",
    "action": "open"
  }
}
```

## Merge request events

Triggered when a new merge request is created or an existing merge request was updated/merged/closed.

**Request body:**

```json
{
  "object_kind": "merge_request",
  "user": {
    "name": "Administrator",
    "username": "root",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=40\u0026d=identicon"
  },
  "object_attributes": {
    "id": 99,
    "target_branch": "master",
    "source_branch": "ms-viewport",
    "source_project_id": 14,
    "author_id": 51,
    "assignee_id": 6,
    "title": "MS-Viewport",
    "created_at": "2013-12-03T17:23:34Z",
    "updated_at": "2013-12-03T17:23:34Z",
    "st_commits": null,
    "st_diffs": null,
    "milestone_id": null,
    "state": "opened",
    "merge_status": "unchecked",
    "target_project_id": 14,
    "iid": 1,
    "description": "",
    "source": {
      "name": "awesome_project",
      "ssh_url": "ssh://git@example.com/awesome_space/awesome_project.git",
      "http_url": "http://example.com/awesome_space/awesome_project.git",
      "visibility_level": 20,
      "namespace": "awesome_space"
    },
    "target": {
      "name": "awesome_project",
      "ssh_url": "ssh://git@example.com/awesome_space/awesome_project.git",
      "http_url": "http://example.com/awesome_space/awesome_project.git",
      "visibility_level": 20,
      "namespace": "awesome_space"
    },
    "last_commit": {
      "id": "da1560886d4f094c3e6c9ef40349f7d38b5d27d7",
      "message": "fixed readme",
      "timestamp": "2012-01-03T23:36:29+02:00",
      "url": "http://example.com/awesome_space/awesome_project/commits/da1560886d4f094c3e6c9ef40349f7d38b5d27d7",
      "author": {
        "name": "GitLab dev user",
        "email": "gitlabdev@dv6700.(none)"
      }
    }
  }
}
```

#### Example webhook receiver

If you want to see GitLab's webhooks in action for testing purposes you can use
a simple echo script running in a console session.

Save the following file as `print_http_body.rb`.

```ruby
require 'webrick'

server = WEBrick::HTTPServer.new(:Port => ARGV.first)
server.mount_proc '/' do |req, res|
  puts req.body
end

trap 'INT' do 
  server.shutdown 
end
server.start
```

Pick an unused port (e.g. 8000) and start the script: `ruby print_http_body.rb
8000`.  Then add your server as a webhook receiver in GitLab as
`http://my.host:8000/`.

When you press 'Test Hook' in GitLab, you should see something like this in the console.

```
{"before":"077a85dd266e6f3573ef7e9ef8ce3343ad659c4e","after":"95cd4a99e93bc4bbabacfa2cd10e6725b1403c60",<SNIP>}
example.com - - [14/May/2014:07:45:26 EDT] "POST / HTTP/1.1" 200 0
- -> /
```
