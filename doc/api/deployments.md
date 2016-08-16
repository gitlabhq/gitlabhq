# Deployments API

## List project deployments

Get a list of deployments in a project.

```
GET /projects/:id/deployments
```

| Attribute | Type    | Required | Description         |
|-----------|---------|----------|---------------------|
| `id`      | integer | yes      | The ID of a project |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/1/deployments"
```

Example of response

```json
[
  {
    "created_at": "2016-08-11T07:36:40.222Z",
    "deployable": {
      "commit": {
        "author_email": "admin@example.com",
        "author_name": "Administrator",
        "created_at": "2016-08-11T09:36:01.000+02:00",
        "id": "99d03678b90d914dbb1b109132516d71a4a03ea8",
        "message": "Merge branch 'new-title' into 'master'\r\n\r\nUpdate README\r\n\r\n\r\n\r\nSee merge request !1",
        "short_id": "99d03678",
        "title": "Merge branch 'new-title' into 'master'\r"
      },
      "coverage": null,
      "created_at": "2016-08-11T07:36:27.357Z",
      "finished_at": "2016-08-11T07:36:39.851Z",
      "id": 657,
      "name": "deploy",
      "ref": "master",
      "runner": null,
      "stage": "deploy",
      "started_at": null,
      "status": "success",
      "tag": false,
      "user": {
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
        "bio": null,
        "created_at": "2016-08-11T07:09:20.351Z",
        "id": 1,
        "is_admin": true,
        "linkedin": "",
        "location": null,
        "name": "Administrator",
        "skype": "",
        "state": "active",
        "twitter": "",
        "username": "root",
        "web_url": "http://localhost:3000/u/root",
        "website_url": ""
      }
    },
    "environment": {
      "external_url": "https://about.gitlab.com",
      "id": 9,
      "name": "production"
    },
    "id": 41,
    "iid": 1,
    "project": {
      "archived": false,
      "avatar_url": null,
      "builds_enabled": true,
      "container_registry_enabled": true,
      "created_at": "2016-08-11T07:31:46.777Z",
      "creator_id": 1,
      "default_branch": "master",
      "description": "",
      "forks_count": 0,
      "http_url_to_repo": "http://localhost:3000/root/ci-project.git",
      "id": 9,
      "issues_enabled": true,
      "last_activity_at": "2016-08-11T11:32:53.239Z",
      "merge_requests_enabled": true,
      "name": "ci-project",
      "name_with_namespace": "Administrator / ci-project",
      "namespace": {
        "avatar": null,
        "created_at": "2016-08-11T07:09:20.585Z",
        "deleted_at": null,
        "description": "",
        "id": 1,
        "name": "root",
        "owner_id": 1,
        "path": "root",
        "request_access_enabled": true,
        "share_with_group_lock": false,
        "updated_at": "2016-08-11T07:09:20.585Z",
        "visibility_level": 20
      },
      "open_issues_count": 0,
      "owner": {
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
        "id": 1,
        "name": "Administrator",
        "state": "active",
        "username": "root",
        "web_url": "http://localhost:3000/u/root"
      },
      "path": "ci-project",
      "path_with_namespace": "root/ci-project",
      "public": false,
      "public_builds": true,
      "shared_runners_enabled": true,
      "shared_with_groups": [
      ],
      "snippets_enabled": false,
      "ssh_url_to_repo": "ssh://zegerjan@localhost:2222/root/ci-project.git",
      "star_count": 0,
      "tag_list": [
      ],
      "visibility_level": 0,
      "web_url": "http://localhost:3000/root/ci-project",
      "wiki_enabled": true
    },
    "ref": "master",
    "sha": "99d03678b90d914dbb1b109132516d71a4a03ea8",
    "user": {
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "id": 1,
      "name": "Administrator",
      "state": "active",
      "username": "root",
      "web_url": "http://localhost:3000/u/root"
    }
  },
  {
    "created_at": "2016-08-11T11:32:35.444Z",
    "deployable": {
      "commit": {
        "author_email": "admin@example.com",
        "author_name": "Administrator",
        "created_at": "2016-08-11T13:28:26.000+02:00",
        "id": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
        "message": "Merge branch 'rename-readme' into 'master'\r\n\r\nRename README\r\n\r\n\r\n\r\nSee merge request !2",
        "short_id": "a91957a8",
        "title": "Merge branch 'rename-readme' into 'master'\r"
      },
      "coverage": null,
      "created_at": "2016-08-11T11:32:24.456Z",
      "finished_at": "2016-08-11T11:32:35.145Z",
      "id": 664,
      "name": "deploy",
      "ref": "master",
      "runner": null,
      "stage": "deploy",
      "started_at": null,
      "status": "success",
      "tag": false,
      "user": {
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
        "bio": null,
        "created_at": "2016-08-11T07:09:20.351Z",
        "id": 1,
        "is_admin": true,
        "linkedin": "",
        "location": null,
        "name": "Administrator",
        "skype": "",
        "state": "active",
        "twitter": "",
        "username": "root",
        "web_url": "http://localhost:3000/u/root",
        "website_url": ""
      }
    },
    "environment": {
      "external_url": "https://about.gitlab.com",
      "id": 9,
      "name": "production"
    },
    "id": 42,
    "iid": 2,
    "project": {
      "archived": false,
      "avatar_url": null,
      "builds_enabled": true,
      "container_registry_enabled": true,
      "created_at": "2016-08-11T07:31:46.777Z",
      "creator_id": 1,
      "default_branch": "master",
      "description": "",
      "forks_count": 0,
      "http_url_to_repo": "http://localhost:3000/root/ci-project.git",
      "id": 9,
      "issues_enabled": true,
      "last_activity_at": "2016-08-11T11:32:53.239Z",
      "merge_requests_enabled": true,
      "name": "ci-project",
      "name_with_namespace": "Administrator / ci-project",
      "namespace": {
        "avatar": null,
        "created_at": "2016-08-11T07:09:20.585Z",
        "deleted_at": null,
        "description": "",
        "id": 1,
        "name": "root",
        "owner_id": 1,
        "path": "root",
        "request_access_enabled": true,
        "share_with_group_lock": false,
        "updated_at": "2016-08-11T07:09:20.585Z",
        "visibility_level": 20
      },
      "open_issues_count": 0,
      "owner": {
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
        "id": 1,
        "name": "Administrator",
        "state": "active",
        "username": "root",
        "web_url": "http://localhost:3000/u/root"
      },
      "path": "ci-project",
      "path_with_namespace": "root/ci-project",
      "public": false,
      "public_builds": true,
      "shared_runners_enabled": true,
      "shared_with_groups": [
      ],
      "snippets_enabled": false,
      "ssh_url_to_repo": "ssh://zegerjan@localhost:2222/root/ci-project.git",
      "star_count": 0,
      "tag_list": [
      ],
      "visibility_level": 0,
      "web_url": "http://localhost:3000/root/ci-project",
      "wiki_enabled": true
    },
    "ref": "master",
    "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
    "user": {
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "id": 1,
      "name": "Administrator",
      "state": "active",
      "username": "root",
      "web_url": "http://localhost:3000/u/root"
    }
  }
]
```

## Get a specific deployment

```
GET /projects/:id/deployments/:deployment_id
```

| Attribute | Type    | Required | Description         |
|-----------|---------|----------|---------------------|
| `id`      | integer | yes      | The ID of a project |
| `deployment_id` | string  | yes      | The ID of the deployment |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/1/deployment/1"
```

Example of response

```json
{
  "id": 42,
  "iid": 2,
  "ref": "master",
  "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
  "created_at": "2016-08-11T11:32:35.444Z",
  "project": {
    "id": 9,
    "description": "",
    "default_branch": "master",
    "tag_list": [],
    "public": false,
    "archived": false,
    "visibility_level": 0,
    "ssh_url_to_repo": "ssh://zegerjan@localhost:2222/root/ci-project.git",
    "http_url_to_repo": "http://localhost:3000/root/ci-project.git",
    "web_url": "http://localhost:3000/root/ci-project",
    "owner": {
      "name": "Administrator",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://localhost:3000/u/root"
    },
    "name": "ci-project",
    "name_with_namespace": "Administrator / ci-project",
    "path": "ci-project",
    "path_with_namespace": "root/ci-project",
    "issues_enabled": true,
    "merge_requests_enabled": true,
    "wiki_enabled": true,
    "builds_enabled": true,
    "snippets_enabled": false,
    "container_registry_enabled": true,
    "created_at": "2016-08-11T07:31:46.777Z",
    "last_activity_at": "2016-08-11T11:32:53.239Z",
    "shared_runners_enabled": true,
    "creator_id": 1,
    "namespace": {
      "id": 1,
      "name": "root",
      "path": "root",
      "owner_id": 1,
      "created_at": "2016-08-11T07:09:20.585Z",
      "updated_at": "2016-08-11T07:09:20.585Z",
      "description": "",
      "avatar": null,
      "share_with_group_lock": false,
      "visibility_level": 20,
      "request_access_enabled": true,
      "deleted_at": null
    },
    "avatar_url": null,
    "star_count": 0,
    "forks_count": 0,
    "open_issues_count": 0,
    "public_builds": true,
    "shared_with_groups": []
  },
  "user": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://localhost:3000/u/root"
  },
  "environment": {
    "id": 9,
    "name": "production",
    "external_url": "https://about.gitlab.com"
  },
  "deployable": {
    "id": 664,
    "status": "success",
    "stage": "deploy",
    "name": "deploy",
    "ref": "master",
    "tag": false,
    "coverage": null,
    "created_at": "2016-08-11T11:32:24.456Z",
    "started_at": null,
    "finished_at": "2016-08-11T11:32:35.145Z",
    "user": {
      "name": "Administrator",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://localhost:3000/u/root",
      "created_at": "2016-08-11T07:09:20.351Z",
      "is_admin": true,
      "bio": null,
      "location": null,
      "skype": "",
      "linkedin": "",
      "twitter": "",
      "website_url": ""
    },
    "commit": {
      "id": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
      "short_id": "a91957a8",
      "title": "Merge branch 'rename-readme' into 'master'\r",
      "author_name": "Administrator",
      "author_email": "admin@example.com",
      "created_at": "2016-08-11T13:28:26.000+02:00",
      "message": "Merge branch 'rename-readme' into 'master'\r\n\r\nRename README\r\n\r\n\r\n\r\nSee merge request !2"
    },
    "runner": null
  }
}
```
