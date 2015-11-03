# GitLab CI API

## Resources

- [Projects](projects.md)
- [Runners](runners.md)
- [Commits](commits.md)
- [Builds](builds.md)


## Authentication

GitLab CI API uses different types of authentication depends on what API you use.
Each API document has section with information about authentication you need to use.

GitLab CI API has 4 authentication methods:

* GitLab user token & GitLab url
* GitLab CI project token
* GitLab CI runners registration token
* GitLab CI runner token


### Authentication #1: GitLab user token & GitLab url

Authentication is done by
sending the `private-token` of a valid user and the `url` of an
authorized GitLab instance via a query string along with the API
request:

    GET http://gitlab.example.com/ci/api/v1/projects?private_token=QVy1PB7sTxfy4pqfZM1U&url=http://demo.gitlab.com/

If preferred, you may instead send the `private-token` as a header in
your request:

    curl --header "PRIVATE-TOKEN: QVy1PB7sTxfy4pqfZM1U" "http://gitlab.example.com/ci/api/v1/projects?url=http://demo.gitlab.com/"


### Authentication #2: GitLab CI project token

Each project in GitLab CI has it own token. 
It can be used to get project commits and builds information.
You can use project token only for certain project.

### Authentication #3: GitLab CI runners registration token

This token is not persisted and is generated on each application start.
It can be used only for registering new runners in system. You can find it on 
GitLab CI Runners web page https://gitlab-ci.example.com/admin/runners

### Authentication #4: GitLab CI runner token

Every GitLab CI runner has it own token that allow it to receive and update 
GitLab CI builds. This token exists of internal purposes and should be used only 
by runners

## JSON

All API requests are serialized using JSON.  You don't need to specify
`.json` at the end of API URL.

## Status codes

The API is designed to return different status codes according to context and action. In this way if a request results in an error the caller is able to get insight into what went wrong, e.g. status code `400 Bad Request` is returned if a required attribute is missing from the request. The following list gives an overview of how the API functions generally behave.

API request types:

- `GET` requests access one or more resources and return the result as JSON
- `POST` requests return `201 Created` if the resource is successfully created and return the newly created resource as JSON
- `GET`, `PUT` and `DELETE` return `200 OK` if the resource is accessed, modified or deleted successfully, the (modified) result is returned as JSON
- `DELETE` requests are designed to be idempotent, meaning a request a resource still returns `200 OK` even it was deleted before or is not available. The reasoning behind it is the user is not really interested if the resource existed before or not.

The following list shows the possible return codes for API requests.

Return values:

- `200 OK` - The `GET`, `PUT` or `DELETE` request was successful, the resource(s) itself is returned as JSON
- `201 Created` - The `POST` request was successful and the resource is returned as JSON
- `400 Bad Request` - A required attribute of the API request is missing, e.g. the title of an issue is not given
- `401 Unauthorized` - The user is not authenticated, a valid user token is necessary, see above
- `403 Forbidden` - The request is not allowed, e.g. the user is not allowed to delete a project
- `404 Not Found` - A resource could not be accessed, e.g. an ID for a resource could not be found
- `405 Method Not Allowed` - The request is not supported
- `409 Conflict` - A conflicting resource already exists, e.g. creating a project with a name that already exists
- `422 Unprocessable` - The entity could not be processed
- `500 Server Error` - While handling the request something went wrong on the server side
