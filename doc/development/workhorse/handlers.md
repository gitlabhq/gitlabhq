---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
title: Workhorse handlers
---

Long HTTP requests are hard to handle efficiently in Rails.
The requests are either memory-inefficient (file uploads) or impossible at all due to shorter timeouts
(for example, Puma server has 60-second timeout).
Workhorse can efficiently handle a large number of long HTTP requests.
Workhorse acts as a proxy that intercepts all HTTP requests and either propagates them without
changing or handles them itself by performing additional logic.

## Injectors

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
sequenceDiagram
    participant Client
    participant Workhorse
    participant Rails

    Client->>+Workhorse: Request
    Workhorse->>+Rails: Propagate the request as-is
    Rails-->>-Workhorse: Respond with a special header that contains instructions for proceeding with the request
    Workhorse-->>Client: Response
```

### Example: Send a Git blob

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
sequenceDiagram
    participant Client
    participant Workhorse
    participant Rails
    participant Gitaly

    Client->>+Workhorse: HTTP Request for a blob
    Workhorse->>+Rails: Propagate the request as-is
    Rails-->>-Workhorse: Respond with a git-blob:{encoded_data} header
    Workhorse->>+Gitaly: BlobService.GetBlob gRPC request
    Gitaly-->>-Workhorse: BlobService.GetBlob gRPC request
    Workhorse-->>Client: Stream the data
```

### How GitLab Rails processes the request

- [`send_git_blob`](https://gitlab.com/gitlab-org/gitlab/blob/8ba71b1f2feec64aeec52ccac4a1e585ba8052d9/lib/api/files.rb#L161)
- [Send a header with a particular information](https://gitlab.com/gitlab-org/gitlab/blob/8ba71b1f2feec64aeec52ccac4a1e585ba8052d9/lib/gitlab/workhorse.rb#L49-63)

### How Workhorse processes the header

- [Specify a list of injectors](https://gitlab.com/gitlab-org/gitlab/blob/8ba71b1f2feec64aeec52ccac4a1e585ba8052d9/workhorse/internal/upstream/routes.go#L179)
- [Iterate over injectors to find a match](https://gitlab.com/gitlab-org/gitlab/blob/8ba71b1f2feec64aeec52ccac4a1e585ba8052d9/workhorse/internal/senddata/senddata.go#L88)
- [Process a particular request](https://gitlab.com/gitlab-org/gitlab/blob/8ba71b1f2feec64aeec52ccac4a1e585ba8052d9/workhorse/internal/git/blob.go#L23)

#### Example: Send a file

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
sequenceDiagram
    participant Client
    participant Workhorse
    participant Rails
    participant Object Storage

    Client->>+Workhorse: HTTP Request for a file
    Workhorse->>+Rails: Propagate the request as-is
    Rails-->>-Workhorse: Respond with a send-url:{encoded_data} header
    Workhorse->>+Object Storage: Request for a file
    Object Storage-->>-Workhorse: Stream the data
    Workhorse-->>Client: Stream the data
```

## Pre-authorized requests

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
sequenceDiagram
    participant Client
    participant Workhorse
    participant Rails
    participant Object Storage

    Client->>+Workhorse: PUT /artifacts/uploads
    Note right of Rails: Append `/authorize` to the original URL and call Rails for an Auth check
    Workhorse->>+Rails: GET /artifacts/uploads/authorize
    Rails-->>-Workhorse: Authorized successfully

    Client->>+Workhorse: Stream the file content
    Workhorse->>+Object Storage: Upload the file
    Object Storage-->>-Workhorse: Success

    Workhorse->>+Rails: Finalize the request
    Note right of Rails: Workhorse calls the original URL to create a database record
    Rails-->>-Workhorse: Finalized successfully
    Workhorse-->>Client: Uploaded successfully
```

## Git over HTTP(S)

Workhorse accelerates Git over HTTP(S) by handling [Git HTTP protocol](https://www.git-scm.com/docs/http-protocol) requests. For example, Git push/pull may require serving large amounts of data. To avoid transferring it through GitLab Rails, Workhorse only performs authorization checks against GitLab Rails, then performs a Gitaly gRPC request directly, and streams the data from Gitaly to the Git client.

### Git pull

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
sequenceDiagram
participant Git on client
participant Workhorse
participant Rails
participant Gitaly

Note left of Git on client: git clone/fetch
Git on client->>+Workhorse: GET /foo/bar.git/info/refs/?service=git-upload-pack
Workhorse->>+Rails: GET Repositories::GitHttpController#info_refs
Note right of Rails: Access check/Log activity
Rails-->>Workhorse: 200 OK, Gitlab::Workhorse.git_http_ok
Workhorse->>+Gitaly: SmartHTTPService.InfoRefsUploadPack gRPC request
Gitaly -->>-Workhorse: SmartHTTPService.InfoRefsUploadPack gRPC response
Workhorse-->>-Git on client: send info-refs response
Git on client->>+Workhorse: GET /foo/bar.git/info/refs/?service=git-upload-pack
Workhorse->>+Rails: GET Repositories::GitHttpController#git_receive_pack
Note right of Rails: Access check/Update statistics
Rails-->>Workhorse: 200 OK, Gitlab::Workhorse.git_http_ok
Workhorse->>+Gitaly: SmartHTTPService.PostUploadPackWithSidechannel gRPC request
Gitaly -->>-Workhorse: SmartHTTPService.PostUploadPackWithSidechannel gRPC response
Workhorse-->>-Git on client: send response
```

### Git push

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
sequenceDiagram
participant Git on client
participant Workhorse
participant Rails
participant Gitaly

Note left of Git on client: git push
Git on client->>+Workhorse: GET /foo/bar.git/info/refs/?service=git-receive-pack
Workhorse->>+Rails: GET Repositories::GitHttpController#info_refs
Note right of Rails: Access check/Log activity
Rails-->>Workhorse: 200 OK, Gitlab::Workhorse.git_http_ok
Workhorse->>+Gitaly: SmartHTTPService.InfoRefsReceivePack gRPC request
Gitaly -->>-Workhorse: SmartHTTPService.InfoRefsReceivePack gRPC response
Workhorse-->>-Git on client: send info-refs response
Git on client->>+Workhorse: GET /foo/bar.git/info/refs/?service=git-receive-pack
Workhorse->>+Rails: GET Repositories::GitHttpController#git_receive_pack
Note right of Rails: Access check/Update statistics
Rails-->>Workhorse: 200 OK, Gitlab::Workhorse.git_http_ok
Workhorse->>+Gitaly: SmartHTTPService.PostReceivePackWithSidechannel gRPC request
Gitaly -->>-Workhorse: SmartHTTPService.PostReceivePackWithSidechannel gRPC response
Workhorse-->>-Git on client: send response
```
