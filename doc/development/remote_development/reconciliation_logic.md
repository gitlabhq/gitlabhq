---
stage: Create
group: Remote Development
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Workspace reconciliation logic
---

This document shows how different events change the database records and how the communication between
`rails` and `agentk` reflects these events.

Two kinds of workspace reconciliation updates exist: `full` and `partial`.
For more information, see [Types of messages](https://gitlab.com/gitlab-org/workspaces/gitlab-workspaces-docs/-/blob/main/doc/architecture.md#types-of-messages).

## Modeling scenarios for partial synchronization

- `request` - The event that occurs. `CURRENT_DB_STATE` describes the state of the database before any event occurs.
- `include config_to_apply in workspace_rails_info response?`
  - For events `CURRENT_DB_STATE` and `USER_ACTION`, this is not applicable. Signified by a `-`.
  - For events `AGENT_ACTION` - Based on the state of the database before the database is updated by the information received from `agentk` about the workspace, should Rails send the `config_to_apply` information to `agentk` based on the condition `desired_state_updated_at >= responded_to_agent_at`?
- `include deployment_resource_version in workspace_rails_info response?` - Should Rails send the `deployment_resource_version` information to `agentk`?
  - This field is not shown in the table below for brevity as it always evaluates to true in the scenarios below (except for the [one scenario](#no-update-for-workspace-from-agentk-or-from-user) where it is called out).
  - Rules of evaluation:
    - If information about the workspace was received from `agentk`, then Yes
    - If configuration to apply for the workspace is being sent to `agentk`, then Yes
    - Else, No
- `desired_state_updated_at`, `responded_to_agent_at`, `desired_state`, `actual_state` - The state of the database after the event occurs
- `responded_to_agent_at` is always updated to the current timestamp when Rails responds to agent with information about the workspace. The information can include `config_to_apply` or `deployment_resource_version` or both.

### desired: Running / actual: CreationRequested → desired: Running / actual: Running

New workspace is requested by the user which results in a Running actual state.

|                     `request`                      | include `config_to_apply` in `workspace_rails_info` response? | `desired_state` |   `actual_state`    | `desired_state_updated_at` | `responded_to_agent_at` |
|:------------------------------------------------:|:---------------------------------------------------------:|:-------------:|:-----------------:|:------------------------:|:---------------------:|
|        `CURRENT_DB_STATE` - Empty database         |                             -                             |               |                   |                          |                       |
| `USER_ACTION` - User has requested a new workspace |                             -                             |    Running    | CreationRequested |          05:00           |                       |
|     `AGENT_ACTION` - `agentk` reports no info      |                             Y                             |    Running    | CreationRequested |          05:00           |         05:01         |
|  `AGENT_ACTION` - `agentk` reports it as Starting  |                             N                             |    Running    |     Starting      |          05:00           |         05:02         |
|  `AGENT_ACTION` - `agentk` reports it as Running   |                             N                             |    Running    |      Running      |          05:00           |         05:03         |

### desired: Running / actual: CreationRequested → desired: Running / actual: Failed

New workspace is requested by the user which results in a Failed actual state (for example, the container is crashing).

|                     `request`                      | include `config_to_apply` in `workspace_rails_info` response? | `desired_state` |   `actual_state`    | `desired_state_updated_at` | `responded_to_agent_at` |
|:------------------------------------------------:|:---------------------------------------------------------:|:-------------:|:-----------------:|:------------------------:|:---------------------:|
|        `CURRENT_DB_STATE` - Empty database         |                             -                             |               |                   |                          |                       |
| `USER_ACTION` - User has requested a new workspace |                             -                             |    Running    | CreationRequested |          05:00           |                       |
|     `AGENT_ACTION` - `agentk` reports no info      |                             Y                             |    Running    | CreationRequested |          05:00           |         05:01         |
|  `AGENT_ACTION` - `agentk` reports it as Starting  |                             N                             |    Running    |     Starting      |          05:00           |         05:02         |
|  `AGENT_ACTION` - `agentk` reports it as Failing   |                             N                             |    Running    |      Failed       |          05:00           |         05:03         |

### desired: Running / actual: CreationRequested → desired: Running / actual: Error

New workspace is requested by the user which results in an Error actual state (for example, failed to apply Kubernetes resources).

|                     `request`                      | include `config_to_apply` in `workspace_rails_info` response? | `desired_state` |   `actual_state`    | `desired_state_updated_at` | `responded_to_agent_at` |
|:------------------------------------------------:|:---------------------------------------------------------:|:-------------:|:-----------------:|:------------------------:|:---------------------:|
|        `CURRENT_DB_STATE` - Empty database         |                             -                             |               |                   |                          |                       |
| `USER_ACTION` - User has requested a new workspace |                             -                             |    Running    | CreationRequested |          05:00           |                       |
|     `AGENT_ACTION` - `agentk` reports no info      |                             Y                             |    Running    | CreationRequested |          05:00           |         05:01         |
|   `AGENT_ACTION` - `agentk` reports it as Error    |                             N                             |    Running    |       Error       |          05:00           |         05:02         |

### desired: Running / actual: Running → desired: Stopped / actual: Stopped

Running workspace is stopped by the user which results in a Stopped actual state.

|                     `request`                      | include `config_to_apply` in `workspace_rails_info` response? | `desired_state` | `actual_state` | `desired_state_updated_at` | `responded_to_agent_at` |
|:------------------------------------------------:|:---------------------------------------------------------:|:-------------:|:------------:|:------------------------:|:---------------------:|
| `CURRENT_DB_STATE` - Workspace is in Running state |                             -                             |    Running    |   Running    |          05:00           |         05:01         |
|      `USER_ACTION` - User stops the workspace      |                             -                             |    Stopped    |   Running    |          05:02           |         05:01         |
|     `AGENT_ACTION` - `agentk` reports no info      |                             Y                             |    Stopped    |   Running    |          05:02           |         05:03         |
|  `AGENT_ACTION` - `agentk` reports it as Stopping  |                             N                             |    Stopped    |   Stopping   |          05:02           |         05:04         |
|  `AGENT_ACTION` - `agentk` reports it as Stopped   |                             N                             |    Stopped    |   Stopped    |          05:02           |         05:05         |

### desired: Running / actual: Running → desired: Stopped / actual: Failed

Running workspace is stopped by the user which results in a Failed actual state (for example, could not unmount volume and stop the workspace).

|                     `request`                      | include `config_to_apply` in `workspace_rails_info` response? | `desired_state` | `actual_state` | `desired_state_updated_at` | `responded_to_agent_at` |
|:------------------------------------------------:|:---------------------------------------------------------:|:-------------:|:------------:|:------------------------:|:---------------------:|
| `CURRENT_DB_STATE` - Workspace is in Running state |                             -                             |    Running    |   Running    |          05:00           |         05:01         |
|      `USER_ACTION` - User stops the workspace      |                             -                             |    Stopped    |   Running    |          05:02           |         05:01         |
|     `AGENT_ACTION` - `agentk` reports no info      |                             Y                             |    Stopped    |   Running    |          05:02           |         05:03         |
|  `AGENT_ACTION` - `agentk` reports it as Stopping  |                             N                             |    Stopped    |   Stopping   |          05:02           |         05:04         |
|   `AGENT_ACTION` - `agentk` reports it as Failed   |                             N                             |    Stopped    |    Failed    |          05:02           |         05:05         |

### desired: Running / actual: Running → desired: Stopped / actual: Error

Running workspace is stopped by the user which results in an Error actual state (for example, failed to apply Kubernetes resources).

|                     `request`                      | include `config_to_apply` in `workspace_rails_info` response? | `desired_state` | `actual_state` | `desired_state_updated_at` | `responded_to_agent_at` |
|:------------------------------------------------:|:---------------------------------------------------------:|:-------------:|:------------:|:------------------------:|:---------------------:|
| `CURRENT_DB_STATE` - Workspace is in Running state |                             -                             |    Running    |   Running    |          05:00           |         05:01         |
|      `USER_ACTION` - User stops the workspace      |                             -                             |    Stopped    |   Running    |          05:02           |         05:01         |
|     `AGENT_ACTION` - `agentk` reports no info      |                             Y                             |    Stopped    |   Running    |          05:02           |         05:03         |
|   `AGENT_ACTION` - `agentk` reports it as Error    |                             N                             |    Stopped    |    Error     |          05:02           |         05:04         |

### desired: Running / actual: Running → desired: Terminated / actual: Terminated

Running workspace is terminated by the user which results in a Terminated actual state.

|                     `request`                      | include `config_to_apply` in `workspace_rails_info` response? | `desired_state` | `actual_state` | `desired_state_updated_at` | `responded_to_agent_at` |
|:------------------------------------------------:|:---------------------------------------------------------:|:-------------:|:------------:|:------------------------:|:---------------------:|
| `CURRENT_DB_STATE` - Workspace is in Running state |                             -                             |    Running    |   Running    |          05:00           |         05:01         |
|   `USER_ACTION` - User terminates the workspace    |                             -                             |  Terminated   |   Running    |          05:02           |         05:01         |
|     `AGENT_ACTION` - `agentk` reports no info      |                             Y                             |  Terminated   |   Running    |          05:02           |         05:03         |
| `AGENT_ACTION` - `agentk` reports it as Terminated |                             N                             |  Terminated   |  Terminated  |          05:02           |         05:04         |

### desired: Running / actual: Running → desired: Terminated / actual: Failed

Running workspace is terminated by the user which results in a Failed actual state (for example, could not unmount volume and terminate the workspace).

|                     `request`                      | include `config_to_apply` in `workspace_rails_info` response? | `desired_state` | `actual_state` | `desired_state_updated_at` | `responded_to_agent_at` |
|:------------------------------------------------:|:---------------------------------------------------------:|:-------------:|:------------:|:------------------------:|:---------------------:|
| `CURRENT_DB_STATE` - Workspace is in Running state |                             -                             |    Running    |   Running    |          05:00           |         05:01         |
|   `USER_ACTION` - User terminates the workspace    |                             -                             |  Terminated   |   Running    |          05:02           |         05:01         |
|     `AGENT_ACTION` - `agentk` reports no info      |                             Y                             |  Terminated   |   Running    |          05:02           |         05:03         |
|   `AGENT_ACTION` - `agentk` reports it as Failed   |                             N                             |  Terminated   |    Failed    |          05:02           |         05:04         |

### desired: Running / actual: Running → desired: Terminated / actual: Error

Running workspace is terminated by the user which results in an Error actual state (for example, failed to apply Kubernetes resources).

|                     `request`                      | include `config_to_apply` in `workspace_rails_info` response? | `desired_state` | `actual_state` | `desired_state_updated_at` | `responded_to_agent_at` |
|:------------------------------------------------:|:---------------------------------------------------------:|:-------------:|:------------:|:------------------------:|:---------------------:|
| `CURRENT_DB_STATE` - Workspace is in Running state |                             -                             |    Running    |   Running    |          05:00           |         05:01         |
|   `USER_ACTION` - User terminates the workspace    |                             -                             |  Terminated   |   Running    |          05:02           |         05:01         |
|     `AGENT_ACTION` - `agentk` reports no info      |                             Y                             |  Terminated   |   Running    |          05:02           |         05:03         |
|   `AGENT_ACTION` - `agentk` reports it as Error    |                             N                             |  Terminated   |    Error     |          05:02           |         05:04         |

### desired: Stopped / actual: Stopped → desired: Running / actual: Running

Stopped workspace is started by the user which results in a Running actual state.

|                     `request`                      | include `config_to_apply` in `workspace_rails_info` response? | `desired_state` | `actual_state` | `desired_state_updated_at` | `responded_to_agent_at` |
|:------------------------------------------------:|:---------------------------------------------------------:|:-------------:|:------------:|:------------------------:|:---------------------:|
| `CURRENT_DB_STATE` - Workspace is in Stopped state |                             -                             |    Stopped    |   Stopped    |          05:00           |         05:01         |
|     `USER_ACTION` - User starts the workspace      |                             -                             |    Running    |   Stopped    |          05:02           |         05:01         |
|     `AGENT_ACTION` - `agentk` reports no info      |                             Y                             |    Running    |   Stopped    |          05:02           |         05:03         |
|  `AGENT_ACTION` - `agentk` reports it as Starting  |                             N                             |    Running    |   Starting   |          05:02           |         05:04         |
|  `AGENT_ACTION` - `agentk` reports it as Running   |                             N                             |    Running    |   Running    |          05:02           |         05:05         |

### desired: Stopped / actual: Stopped → desired: Running / actual: Failed

Stopped workspace is started by the user which results in a Failed actual state (for example, container is crashing).

|                     `request`                      | include `config_to_apply` in `workspace_rails_info` response? | `desired_state` | `actual_state` | `desired_state_updated_at` | `responded_to_agent_at` |
|:------------------------------------------------:|:---------------------------------------------------------:|:-------------:|:------------:|:------------------------:|:---------------------:|
| `CURRENT_DB_STATE` - Workspace is in Stopped state |                             -                             |    Stopped    |   Stopped    |          05:00           |         05:01         |
|     `USER_ACTION` - User starts the workspace      |                             -                             |    Running    |   Stopped    |          05:02           |         05:01         |
|     `AGENT_ACTION` - `agentk` reports no info      |                             Y                             |    Running    |   Stopped    |          05:02           |         05:03         |
|  `AGENT_ACTION` - `agentk` reports it as Starting  |                             N                             |    Running    |   Starting   |          05:02           |         05:04         |
|   `AGENT_ACTION` - `agentk` reports it as Failed   |                             N                             |    Running    |    Failed    |          05:02           |         05:05         |

### desired: Stopped / actual: Stopped → desired: Running / actual: Error

Stopped workspace is started by the user which results in an Error actual state (for example, failed to apply Kubernetes resources).

|                     `request`                      | include `config_to_apply` in `workspace_rails_info` response? | `desired_state` | `actual_state` | `desired_state_updated_at` | `responded_to_agent_at` |
|:------------------------------------------------:|:----------------------------------------------------------|:-------------:|:------------:|:------------------------:|:---------------------:|
| `CURRENT_DB_STATE` - Workspace is in Stopped state | -                                                         |    Stopped    |   Stopped    |          05:00           |         05:01         |
|     `USER_ACTION` - User starts the workspace      | -                                                         |    Running    |   Stopped    |          05:02           |         05:01         |
|     `AGENT_ACTION` - `agentk` reports no info      | Y                                                         |    Running    |   Stopped    |          05:02           |         05:03         |
|   `AGENT_ACTION` - `agentk` reports it as Error    | N                                                         |    Running    |    Error     |          05:02           |         05:04         |

### desired: Stopped / actual: Stopped → desired: Terminated / actual: Terminated

Stopped workspace is terminated by the user which results in a Terminated actual state.

|                     `request`                      | include `config_to_apply` in `workspace_rails_info` response? | `desired_state` | `actual_state` | `desired_state_updated_at` | `responded_to_agent_at` |
|:------------------------------------------------:|:---------------------------------------------------------:|:-------------:|:------------:|:------------------------:|:---------------------:|
| `CURRENT_DB_STATE` - Workspace is in Stopped state |                             -                             |    Stopped    |   Stopped    |          05:00           |         05:01         |
|   `USER_ACTION` - User terminates the workspace    |                             -                             |  Terminated   |   Stopped    |          05:02           |         05:01         |
|     `AGENT_ACTION` - `agentk` reports no info      |                             Y                             |  Terminated   |   Stopped    |          05:02           |         05:03         |
| `AGENT_ACTION` - `agentk` reports it as Terminated |                             N                             |  Terminated   |  Terminated  |          05:02           |         05:04         |

### desired: Stopped / actual: Stopped → desired: Terminated / actual: Failed

Stopped workspace is terminated by the user which results in a Failed actual state (for example, could not unmount volume and terminate the workspace).

|                     `request`                      | include `config_to_apply` in `workspace_rails_info` response? | `desired_state` | `actual_state` | `desired_state_updated_at` | `responded_to_agent_at` |
|:------------------------------------------------:|:---------------------------------------------------------:|:-------------:|:------------:|:------------------------:|:---------------------:|
| `CURRENT_DB_STATE` - Workspace is in Stopped state |                             -                             |    Stopped    |   Stopped    |          05:00           |         05:01         |
|   `USER_ACTION` - User terminates the workspace    |                             -                             |  Terminated   |   Stopped    |          05:02           |         05:01         |
|     `AGENT_ACTION` - `agentk` reports no info      |                             Y                             |  Terminated   |   Stopped    |          05:02           |         05:03         |
|   `AGENT_ACTION` - `agentk` reports it as Failed   |                             N                             |  Terminated   |    Failed    |          05:02           |         05:04         |

### desired: Stopped / actual: Stopped → desired: Terminated / actual: Error

Stopped workspace is terminated by the user which results in an Error actual state (for example, failed to apply Kubernetes resources).

|                     `request`                      | include `config_to_apply` in `workspace_rails_info` response? | `desired_state` | `actual_state` | `desired_state_updated_at` | `responded_to_agent_at` |
|:------------------------------------------------:|:---------------------------------------------------------:|:-------------:|:------------:|:------------------------:|:---------------------:|
| `CURRENT_DB_STATE` - Workspace is in Stopped state |                             -                             |    Stopped    |   Stopped    |          05:00           |         05:01         |
|   `USER_ACTION` - User terminates the workspace    |                             -                             |  Terminated   |   Stopped    |          05:02           |         05:01         |
|     `AGENT_ACTION` - `agentk` reports no info      |                             Y                             |  Terminated   |   Stopped    |          05:02           |         05:03         |
|   `AGENT_ACTION` - `agentk` reports it as Error    |                             N                             |  Terminated   |    Error     |          05:02           |         05:04         |

### desired: Running / actual: Failed → desired: Running / actual: Running

Failed workspace becomes ready which results in a Running actual state (for example, container is no longer crashing).

|                     `request`                     | include `config_to_apply` in `workspace_rails_info` response? | `desired_state` | `actual_state` | `desired_state_updated_at` | `responded_to_agent_at` |
|:-----------------------------------------------:|:---------------------------------------------------------:|:-------------:|:------------:|:------------------------:|:---------------------:|
| `CURRENT_DB_STATE` - Workspace is in Failed state |                             -                             |    Running    |    Failed    |          05:00           |         05:01         |
| `AGENT_ACTION` - `agentk` reports it as Starting  |                             N                             |    Running    |   Starting   |          05:00           |         05:02         |
|  `AGENT_ACTION` - `agentk` reports it as Running  |                             N                             |    Running    |   Running    |          05:00           |         05:03         |

### desired: Running / actual: Failed → desired: Stopped / actual: Stopped

Failed workspace is stopped by the user which results in a Stopped actual state.

|                     `request`                     | include `config_to_apply` in `workspace_rails_info` response? | `desired_state` | `actual_state` | `desired_state_updated_at` | `responded_to_agent_at` |
|:-----------------------------------------------:|:---------------------------------------------------------:|:-------------:|:------------:|:------------------------:|:---------------------:|
| `CURRENT_DB_STATE` - Workspace is in Failed state |                             -                             |    Running    |    Failed    |          05:00           |         05:01         |
|     `USER_ACTION` - User stops the workspace      |                             -                             |    Stopped    |    Failed    |          05:02           |         05:01         |
|     `AGENT_ACTION` - `agentk` reports no info     |                             Y                             |    Stopped    |    Failed    |          05:02           |         05:03         |
| `AGENT_ACTION` - `agentk` reports it as Stopping  |                             N                             |    Stopped    |   Stopping   |          05:02           |         05:04         |
|  `AGENT_ACTION` - `agentk` reports it as Stopped  |                             N                             |    Stopped    |   Stopped    |          05:02           |         05:05         |

### desired: Running / actual: Failed → desired: Stopped / actual: Failed

Failed workspace is stopped by the user which results in a Failed actual state (for example, could not unmount the volume and stop the workspace).

|                     `request`                     | include `config_to_apply` in `workspace_rails_info` response? | `desired_state` | `actual_state` | `desired_state_updated_at` | `responded_to_agent_at` |
|:-----------------------------------------------:|:---------------------------------------------------------:|:-------------:|:------------:|:------------------------:|:---------------------:|
| `CURRENT_DB_STATE` - Workspace is in Failed state |                             -                             |    Running    |    Failed    |          05:00           |         05:01         |
|     `USER_ACTION` - User stops the workspace      |                             -                             |    Stopped    |    Failed    |          05:02           |         05:01         |
|     `AGENT_ACTION` - `agentk` reports no info     |                             Y                             |    Stopped    |    Failed    |          05:02           |         05:03         |
|  `AGENT_ACTION` - `agentk` reports it as Failed   |                             N                             |    Stopped    |    Failed    |          05:02           |         05:04         |

### desired: Running / actual: Failed → desired: Stopped / actual: Error

Failed workspace is stopped by the user which results in an Error actual state (for example, failed to apply Kubernetes resources).

|                     `request`                     | include `config_to_apply` in `workspace_rails_info` response? | `desired_state` | `actual_state` | `desired_state_updated_at` | `responded_to_agent_at` |
|:-----------------------------------------------:|:---------------------------------------------------------:|:-------------:|:------------:|:------------------------:|:---------------------:|
| `CURRENT_DB_STATE` - Workspace is in Failed state |                             -                             |    Running    |    Failed    |          05:00           |         05:01         |
|     `USER_ACTION` - User stops the workspace      |                             -                             |    Stopped    |    Failed    |          05:02           |         05:01         |
|     `AGENT_ACTION` - `agentk` reports no info     |                             Y                             |    Stopped    |    Failed    |          05:02           |         05:03         |
|   `AGENT_ACTION` - `agentk` reports it as Error   |                             N                             |    Stopped    |    Error     |          05:02           |         05:04         |

### desired: Running / actual: Failed → desired: Terminated / actual: Terminated

Failed workspace is terminated by the user which results in a Terminated actual state.

| `request` | include `config_to_apply` in `workspace_rails_info` response? | `desired_state` | `actual_state` | `desired_state_updated_at` | `responded_to_agent_at` |
|:---:|:---:|:---:|:---:|:---:|:---:|
| `CURRENT_DB_STATE` - Workspace is in Failed state | - | Running | Failed | 05:00 | 05:01 |
| `USER_ACTION` - User terminates the workspace | - | Terminated | Failed | 05:02 | 05:01 |
| `AGENT_ACTION` - `agentk` reports no info | Y | Terminated | Failed | 05:02 | 05:03 |
| `AGENT_ACTION` - `agentk` reports it as Terminated | N | Terminated | Terminated | 05:02 | 05:04 |

### desired: Running / actual: Failed → desired: Terminated / actual: Failed

Failed workspace is terminated by the user which results in a Failed actual state (for example, could not unmount volume and terminate the workspace).

|                     `request`                     | include `config_to_apply` in `workspace_rails_info` response? | `desired_state` | `actual_state` | `desired_state_updated_at` | `responded_to_agent_at` |
|:-----------------------------------------------:|:---------------------------------------------------------:|:-------------:|:------------:|:------------------------:|:---------------------:|
| `CURRENT_DB_STATE` - Workspace is in Failed state |                             -                             |    Running    |    Failed    |          05:00           |         05:01         |
|   `USER_ACTION` - User terminates the workspace   |                             -                             |  Terminated   |    Failed    |          05:02           |         05:01         |
|     `AGENT_ACTION` - `agentk` reports no info     |                             Y                             |  Terminated   |    Failed    |          05:02           |         05:03         |
|  `AGENT_ACTION` - `agentk` reports it as Failed   |                             N                             |  Terminated   |    Failed    |          05:02           |         05:04         |

### desired: Running / actual: Failed → desired: Terminated / actual: Error

Failed workspace is terminated by the user which results in an Error actual state (for example, failed to apply Kubernetes resources).

|                     `request`                     | include `config_to_apply` in `workspace_rails_info` response? | `desired_state` | `actual_state` | `desired_state_updated_at` | `responded_to_agent_at` |
|:-----------------------------------------------:|:---------------------------------------------------------:|:-------------:|:------------:|:------------------------:|:---------------------:|
| `CURRENT_DB_STATE` - Workspace is in Failed state |                             -                             |    Running    |    Failed    |          05:00           |         05:01         |
|   `USER_ACTION` - User terminates the workspace   |                             -                             |  Terminated   |    Failed    |          05:02           |         05:01         |
|     `AGENT_ACTION` - `agentk` reports no info     |                             Y                             |  Terminated   |    Failed    |          05:02           |         05:03         |
|   `AGENT_ACTION` - `agentk` reports it as Error   |                             N                             |  Terminated   |    Error     |          05:02           |         05:04         |

### desired: Running / actual: Error → desired: Stopped / actual: Error

Error workspace is stopped by the user which results in an Error actual state (for example, failed to apply Kubernetes resources).

{{< alert type="note" >}}

This transition might not be allowed.

{{< /alert >}}

|                     `request`                     | include `config_to_apply` in `workspace_rails_info` response? | `desired_state` | `actual_state` | `desired_state_updated_at` | `responded_to_agent_at` |
|:-----------------------------------------------:|:---------------------------------------------------------:|:-------------:|:------------:|:------------------------:|:---------------------:|
| `CURRENT_DB_STATE` - Workspace is in Failed state |                             -                             |    Running    |    Failed    |          05:00           |         05:01         |
|   `USER_ACTION` - User terminates the workspace   |                             -                             |  Terminated   |    Failed    |          05:02           |         05:01         |
|     `AGENT_ACTION` - `agentk` reports no info     |                             Y                             |  Terminated   |    Failed    |          05:02           |         05:03         |
|   `AGENT_ACTION` - `agentk` reports it as Error   |                             N                             |  Terminated   |    Error     |          05:02           |         05:04         |

### desired: Running / actual: Error → desired: Terminated / actual: Error

Error workspace is terminated by the user which results in an Error actual state (for example, failed to apply Kubernetes resources).

{{< alert type="note" >}}

This transition might not be allowed. Further evaluation is needed to determine if uncleaned state is left behind if this isn't allowed. Consider what happens if the workspace was never created in the first place, or if the workspace was successfully created but entered the Error state while it was being stopped.

{{< /alert >}}

|                     `request`                     | include `config_to_apply` in `workspace_rails_info` response? | `desired_state` | `actual_state` | `desired_state_updated_at` | `responded_to_agent_at` |
|:-----------------------------------------------:|:---------------------------------------------------------:|:-------------:|:------------:|:------------------------:|:---------------------:|
| `CURRENT_DB_STATE` - Workspace is in Failed state |                             -                             |    Running    |    Failed    |          05:00           |         05:01         |
|   `USER_ACTION` - User terminates the workspace   |                             -                             |  Terminated   |    Failed    |          05:02           |         05:01         |
|     `AGENT_ACTION` - `agentk` reports no info     |                             Y                             |  Terminated   |    Failed    |          05:02           |         05:03         |
|   `AGENT_ACTION` - `agentk` reports it as Error   |                             N                             |  Terminated   |    Error     |          05:02           |         05:04         |

## Other scenarios

### Agent reports update for a workspace and user has also updated desired state of the workspace

This scenario shows when `agentk` is reporting on a workspace and the user has also performed an action on the workspace. This highlights that this logic works even in cases where there is new information on both sides (agent and Rails).

Details of the scenario:

- Workspace was earlier running
- Workspace has now started crashing (Failed state)
- User stops the workspace because they no longer need it (without being aware that the workspace has started crashing)

|                     `request`                      | include `config_to_apply` in `workspace_rails_info` response? | `desired_state` | `actual_state` | `desired_state_updated_at` | `responded_to_agent_at` |
|:------------------------------------------------:|:---------------------------------------------------------:|:-------------:|:------------:|:------------------------:|:---------------------:|
| `CURRENT_DB_STATE` - Workspace is in Running state |                             -                             |    Running    |   Running    |          05:00           |         05:01         |
|      `USER_ACTION` - User stops the workspace      |                             -                             |    Stopped    |   Running    |          05:02           |         05:01         |
|   `AGENT_ACTION` - `agentk` reports it as Failed   |                             Y                             |    Stopped    |    Failed    |          05:02           |         05:03         |
|  `AGENT_ACTION` - `agentk` reports it as Stopping  |                             N                             |    Stopped    |   Stopping   |          05:02           |         05:04         |
|  `AGENT_ACTION` - `agentk` reports it as Stopped   |                             N                             |    Stopped    |   Stopped    |          05:02           |         05:05         |

### Restarting a workspace

Running workspace is restarted by the user which results in a Running actual state.

|                                            `request`                                            | include `config_to_apply` in `workspace_rails_info` response? |  `desired_state`   | `actual_state` | `desired_state_updated_at` | `responded_to_agent_at` |
|:---------------------------------------------------------------------------------------------:|:---------------------------------------------------------:|:----------------:|:------------:|:------------------------:|:---------------------:|
|                       `CURRENT_DB_STATE` - Workspace is in Running state                        |                             -                             |     Running      |   Running    |          05:00           |         05:01         |
|                                  User restarts the workspace                                  |                             -                             | RestartRequested |   Running    |          05:02           |         05:01         |
|                            `AGENT_ACTION` - `agentk` reports no info                            |                             Y                             | RestartRequested |   Running    |          05:02           |         05:03         |
|                        `AGENT_ACTION` - `agentk` reports it as Stopping                         |                             N                             | RestartRequested |   Stopping   |          05:02           |         05:04         |
| `AGENT_ACTION` - `agentk` reports it as Stopped, desired_state automatically changed to Running |                             Y                             |     Running      |   Stopped    |          05:05           |         05:05         |
|                        `AGENT_ACTION` - `agentk` reports it as Starting                         |                             N                             |     Running      |   Starting   |          05:05           |         05:07         |
|                         `AGENT_ACTION` - `agentk` reports it as Running                         |                             N                             |     Running      |   Running    |          05:05           |         05:08         |

### No update for workspace from `agentk` or from user

Since Rails does not information about this workspace in the response to `agentk`:

- `include deployment_resource_version in workspace_rails_info response?` is set to `N`
- `responded_to_agent_at` is not updated

|                     `request`                      | include `config_to_apply` in `workspace_rails_info` response? | `desired_state` | `actual_state` | `desired_state_updated_at` | `responded_to_agent_at` |
|:------------------------------------------------:|:---------------------------------------------------------:|:-------------:|:------------:|:------------------------:|:---------------------:|
| `CURRENT_DB_STATE` - Workspace is in Running state |                             -                             |    Running    |   Running    |          05:00           |         05:01         |
|     `AGENT_ACTION` - `agentk` reports no info      |                             N                             |    Running    |   Running    |          05:00           |         05:01         |

{{< alert type="note" >}}

The `Unknown` actual state has not been modeled yet because when that would occur and what would happen is not known. `Unknown` is a fail-safe state which should never occur ideally.

{{< /alert >}}
