## List Commits

Get a list of project commits.

```
GET /projects/:id/commits
```

Parameters:

+ `id` (required) - The ID or code name of a project
+ `ref_name` (optional) - branch/tag name
+ `page` (optional)
+ `per_page` (optional)


```json

[
  {
      "id": "ed899a2f4b50b4370feeea94676502b42383c746",
      "short_id": "ed899a2f4b5",
      "title": "Replace sanitize with escape once",
      "author_name": "Dmitriy Zaporozhets",
      "author_email": "dzaporozhets@sphereconsultinginc.com",
      "created_at": "2012-09-20T11:50:22+03:00"
  },
  {
      "id": "6104942438c14ec7bd21c6cd5bd995272b3faff6",
      "short_id": "6104942438c",
      "title": "Sanitize for network graph",
      "author_name": "randx",
      "author_email": "dmitriy.zaporozhets@gmail.com",
      "created_at": "2012-09-20T09:06:12+03:00"
  }
]

```
