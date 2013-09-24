## User teams

### List user teams

Get a list of user teams viewable by the authenticated user.

```
GET /user_teams
```

```json
[
    {
        id: 1,
        name: "User team 1",
        path: "user_team1",
        owner_id: 1
    },
    {
        id: 2,
        name: "User team 2",
        path: "user_team2",
        owner_id: 1
    }
]
```


### Get single user team

Get a specific user team, identified by user team ID, which is viewable by the authenticated user.

```
GET /user_teams/:id
```

Parameters:

+ `id` (required) - The ID of a user_team

```json
{
    id: 1,
    name: "User team 1",
    path: "user_team1",
    owner_id: 1
}
```


### Create user team

Creates new user team owned by user. Available only for admins.

```
POST /user_teams
```

Parameters:

+ `name` (required) - new user team name
+ `path` (required) - new user team internal name



## User team members

### List user team members

Get a list of project team members.

```
GET /user_teams/:id/members
```

Parameters:

+ `id` (required) - The ID of a user_team


### Get user team member

Gets a user team member.

```
GET /user_teams/:id/members/:user_id
```

Parameters:

+ `id` (required) - The ID of a user_team
+ `user_id` (required) - The ID of a user

```json
{
    id: 2,
    username: "john_doe",
    email: "joh@doe.org",
    name: "John Doe",
    state: "active",
    created_at: "2012-10-22T14:13:35Z",
    access_level: 30
}
```


### Add user team member

Adds a user to a user team.

```
POST /user_teams/:id/members
```

Parameters:

+ `id` (required) - The ID of a user team
+ `user_id` (required) - The ID of a user to add
+ `access_level` (required) - Project access level


### Remove user team member

Removes user from user team.

```
DELETE /user_teams/:id/members/:user_id
```

Parameters:

+ `id` (required) - The ID of a user team
+ `user_id` (required) - The ID of a team member

## User team projects

### List user team projects

Get a list of project team projects.

```
GET /user_teams/:id/projects
```

Parameters:

+ `id` (required) - The ID of a user_team


### Get user team project

Gets a user team project.

```
GET /user_teams/:id/projects/:project_id
```

Parameters:

+ `id` (required) - The ID of a user_team
+ `project_id` (required) - The ID of a user

```json
{
    id: 12,
    name: "project1",
    description: null,
    default_branch: "develop",
    public: false,
    path: "project1",
    path_with_namespace: "group1/project1",
    issues_enabled: false,
    merge_requests_enabled: true,
    wall_enabled: true,
    wiki_enabled: false,
    created_at: "2013-03-11T12:59:08Z",
    greatest_access_level: 30
}
```


### Add user team project

Adds a project to a user team.

```
POST /user_teams/:id/projects
```

Parameters:

+ `id` (required) - The ID of a user team
+ `project_id` (required) - The ID of a project to add
+ `greatest_access_level` (required) - Maximum project access level


### Remove user team project

Removes project from user team.

```
DELETE /user_teams/:id/projects/:project_id
```

Parameters:

+ `id` (required) - The ID of a user team
+ `project_id` (required) - The ID of a team project

