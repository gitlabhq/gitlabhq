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
| `deployment_id` | integer | yes      | The ID of the deployment |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/1/deployments/1"
```

Example of response

```json
{
  "id": 42,
  "iid": 2,
  "ref": "master",
  "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
  "created_at": "2016-08-11T11:32:35.444Z",
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
