## List project milestones

Get a list of project milestones.

```
GET /projects/:id/milestones
```

Parameters:

+ `id` (required) - The ID of a project

## Single milestone

Get a single project milestone.

```
GET /projects/:id/milestones/:milestone_id
```

Parameters:

+ `id` (required) - The ID of a project
+ `milestone_id` (required) - The ID of a project milestone

## New milestone

Create a new project milestone.

```
POST /projects/:id/milestones
```

Parameters:

+ `id` (required) - The ID of a project
+ `milestone_id` (required) - The ID of a project milestone
+ `title` (required) - The title of an milestone
+ `description` (optional) - The description of the milestone
+ `due_date` (optional) - The due date of the milestone

## Edit milestone

Update an existing project milestone.

```
PUT /projects/:id/milestones/:milestone_id
```

Parameters:

+ `id` (required) - The ID of a project
+ `milestone_id` (required) - The ID of a project milestone
+ `title` (optional) - The title of a milestone
+ `description` (optional) - The description of a milestone
+ `due_date` (optional) - The due date of the milestone
+ `closed` (optional) - The status of the milestone
