# Labels

## List labels

Get all labels for given project.

```
GET /projects/:id/labels
```

```json
[
    {
        "name": "Awesome",
        "color": "#DD10AA"
    },
    {
        "name": "Documentation",
        "color": "#1E80DD"
    },
    {
        "name": "Feature",
        "color": "#11FF22"
    },
    {
        "name": "Bug",
        "color": "#EE1122"
    }
]
```

## Create a new label

Creates a new label for given repository with given name and color.

```
POST /projects/:id/labels
```

Parameters:

- `id` (required) - The ID of a project
- `name` (required) - The name of the label
- `color` (required) -  Color of the label given in 6-digit hex notation with leading '#' sign (e.g. #FFAABB)

It returns 200 and the newly created label, if the operation succeeds.
If the label already exists, 409 and an error message is returned.
If label parameters are invalid, 400 and an explaining error message is returned.

## Delete a label

Deletes a label given by its name.

```
DELETE /projects/:id/labels
```

- `id` (required) - The ID of a project
- `name` (required) - The name of the label to be deleted

It returns 200 if the label successfully was deleted, 400 for wrong parameters
and 404 if the label does not exist.
In case of an error, additionally an error message is returned.

## Edit an existing label

Updates an existing label with new name or now color. At least one parameter
is required, to update the label.

```
PUT /projects/:id/labels
```

Parameters:

- `id` (required) - The ID of a project
- `name` (required) - The name of the existing label
- `new_name` (optional) - The new name of the label
- `color` (optional) -  New color of the label given in 6-digit hex notation with leading '#' sign (e.g. #FFAABB)

On success, this method returns 200 with the updated label.
If required parameters are missing or parameters are invalid, 400 is returned.
If the label to be updated is missing, 404 is returned.
In case of an error, additionally an error message is returned.
