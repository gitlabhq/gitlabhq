## List project milestones

Returns a list of project milestones.

```
GET /projects/:id/milestones
```

Parameters:

+ `id` (required) - The ID of a project

Return values:

+ `200 Ok` on success and the list of project milestones
+ `401 Unauthorized` if user is not authenticated
+ `404 Not Found` if project ID not found


## Get single milestone

Gets a single project milestone.

```
GET /projects/:id/milestones/:milestone_id
```

Parameters:

+ `id` (required) - The ID of a project
+ `milestone_id` (required) - The ID of a project milestone

Return values:

+ `200 Ok` on success and the single milestone
+ `401 Unauthorized` if user is not authenticated
+ `404 Not Found` if project ID not found


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

Return values:

+ `201 Created` on success and the new milestone
+ `400 Bad Request` if the required attribute title is not given
+ `401 Unauthorized` if user is not authenticated
+ `404 Not Found` if project ID not found


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
+ `closed` (optional) - The status of the milestone

Return values:

+ `200 Ok` on success and the updated milestone
+ `401 Unauthorized` if user is not authenticated
+ `404 Not Found` if project ID or milestone ID not found
