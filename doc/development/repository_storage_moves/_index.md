---
stage: Create
group: Source Code
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Project Repository Storage Moves
---

This document was created to help contributors understand the code design of
[project repository storage moves](../../api/project_repository_storage_moves.md).
Read this document before making changes to the code for this feature.

This document is intentionally limited to an overview of how the code is
designed, as code can change often. To understand how a specific part of the
feature works, view the code and the specs. The details here explain how the
major components of the Code Owners feature work.

NOTE:
This document should be updated when parts of the codebase referenced in this
document are updated, removed, or new parts are added.

## Business logic

- `Projects::RepositoryStorageMove`: Tracks the move, includes state machine.
  - Defined in `app/models/projects/repository_storage_move.rb`.
- `RepositoryStorageMovable`: Contains the state machine logic, validators, and some helper methods.
  - Defined in `app/models/concerns/repository_storage_movable.rb`.
- `Project`: The project model.
  - Defined in `app/models/project.rb`.
- `CanMoveRepositoryStorage`: Contains helper methods that are into `Project`.
  - Defined in `app/models/concerns/can_move_repository_storage.rb`.
- `API::ProjectRepositoryStorageMoves`: API class for project repository storage moves.
  - Defined in `lib/api/project_repository_storage_moves.rb`.
- `Entities::Projects::RepositoryStorageMove`: API entity for serializing the `Projects::RepositoryStorageMove` model.
  - Defined in `lib/api/entities/projects/repository_storage_moves.rb`.
- `Projects::ScheduleBulkRepositoryShardMovesService`: Service to schedule bulk moves.
  - Defined in `app/services/projects/schedule_bulk_repository_shard_moves_service.rb`.
- `ScheduleBulkRepositoryShardMovesMethods`: Generic methods for bulk moves.
  - Defined in `app/services/concerns/schedule_bulk_repository_shard_moves_methods.rb`.
- `Projects::ScheduleBulkRepositoryShardMovesWorker`: Worker to handle bulk moves.
  - Defined in `app/workers/projects/schedule_bulk_repository_shard_moves_worker.rb`.
- `Projects::UpdateRepositoryStorageWorker`: Finds repository storage move and then calls the update storage service.
  - Defined in `app/workers/projects/update_repository_storage_worker.rb`.
- `UpdateRepositoryStorageWorker`: Module containing generic logic for `Projects::UpdateRepositoryStorageWorker`.
  - Defined in `app/workers/concerns/update_repository_storage_worker.rb`.
- `Projects::UpdateRepositoryStorageService`: Performs the move.
  - Defined in `app/services/projects/update_repository_storage_service.rb`.
- `UpdateRepositoryStorageMethods`: Module with generic methods included in `Projects::UpdateRepositoryStorageService`.
  - Defined in `app/services/concerns/update_repository_storage_methods.rb`.
- `Projects::UpdateService`: Schedules move if the passed parameters request a move.
  - Defined in `app/services/projects/update_service.rb`.
- `PoolRepository`: Ruby object representing Gitaly `ObjectPool`.
  - Defined in `app/models/pool_repository.rb`.
- `ObjectPool::CreateWorker`: Worker to create an `ObjectPool` with `Gitaly`.
  - Defined in `app/workers/object_pool/create_worker.rb`.
- `ObjectPool::JoinWorker`: Worker to join an `ObjectPool` with `Gitaly`.
  - Defined in `app/workers/object_pool/join_worker.rb`.
- `ObjectPool::ScheduleJoinWorker`: Worker to schedule an `ObjectPool::JoinWorker`.
  - Defined in `app/workers/object_pool/schedule_join_worker.rb`.
- `ObjectPool::DestroyWorker`: Worker to destroy an `ObjectPool` with `Gitaly`.
  - Defined in `app/workers/object_pool/destroy_worker.rb`.
- `ObjectPoolQueue`: Module to configure `ObjectPool` workers.
  - Defined in `app/workers/concerns/object_pool_queue.rb`.
- `Repositories::ReplicateService`: Handles replication of data from one repository to another.
  - Defined in `app/services/repositories/replicate_service.rb`.

## Flow

These flowcharts should help explain the flow from the endpoints down to the
models for different features.

### Schedule a repository storage move with the API

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
graph TD
  A[<code>POST /api/:version/project_repository_storage_moves</code>] --> C
  B[<code>POST /api/:version/projects/:id/repository_storage_moves</code>] --> D
  C[Schedule move for each project in shard] --> D[Set state to scheduled]
  D --> E[<code>after_transition callback</code>]
  E --> F{<code>set_repository_read_only!</code>}
  F -->|success| H[Schedule repository update worker]
  F -->|error| G[Set state to failed]
```

### Moving the storage after being scheduled

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
graph TD
  A[Repository update worker scheduled] --> B{State is scheduled?}
  B -->|Yes| C[Set state to started]
  B -->|No| D[Return success]
  C --> E{Same filesystem?}
  E -.-> G[Set project repo to writable]
  E -->|Yes| F["Mirror repositories (project, wiki, design, & pool)"]
  G --> H[Update repo storage value]
  H --> I[Set state to finished]
  I --> J[Associate project with new pool repository]
  J --> K[Unlink old pool repository]
  K --> L[Update project repository storage values]
  L --> N[Remove old paths if same filesystem]
  N --> M[Set state to finished]
```
