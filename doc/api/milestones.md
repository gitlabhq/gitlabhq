## List project milestones

Returns a list of project milestones.

```
GET /projects/:id/milestones
```

Parameters:

+ `id` (required) - The ID of a project


## Get single milestone

Gets a single project milestone.

```
GET /projects/:id/milestones/:milestone_id
```

Parameters:

+ `id` (required) - The ID of a project
+ `milestone_id` (required) - The ID of a project milestone


## Create new milestone

Creates a new project milestone.

```
POST /projects/:id/milestones
```

Parameters:

+ `id` (required) - The ID of a project
+ `title` (required) - The title of an milestone
+ `description` (optional) - The description of the milestone
+ `due_date` (optional) - The due date of the milestone


## Edit milestone

Updates an existing project milestone.

```
PUT /projects/:id/milestones/:milestone_id
```

Parameters:

+ `id` (required) - The ID of a project
+ `milestone_id` (required) - The ID of a project milestone
+ `title` (optional) - The title of a milestone
+ `description` (optional) - The description of a milestone
+ `due_date` (optional) - The due date of the milestone
+ `state_event` (optional) - The state event of the milestone (close|activate)

