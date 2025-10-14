---
stage: Verify
group: Pipeline Execution
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Two-phase commit for CI/CD jobs
---

The two-phase commit feature introduces a new workflow for GitLab Runner job execution that addresses timing accuracy and reliability issues in the current job assignment process.

## Problem statement

In the current workflow, when a GitLab Runner requests a job, the job is immediately transitioned from `pending` to `running` state, even though the runner may still be performing preparation tasks such as:

- Finding or provisioning execution capacity
- Setting up the execution environment
- Downloading dependencies

This immediate transition can lead to:

1. **Misleading job timing**: Preparation time is counted as execution time
1. **Compute minute accuracy issues**: Preparation time may be counted toward compute minutes
1. **Job assignment reliability**: Jobs assigned to runners that go offline during preparation remain stuck until
   timeout

## Solution: Two-phase commit

The two-phase commit feature introduces a new workflow where:

1. **Phase 1 - Job Assignment**: Runner requests and receives a job, but the job remains in `pending` state
1. **Phase 2 - Job Acceptance**: Runner completes preparation and explicitly signals readiness to start execution

### Workflow comparison

#### Current workflow (legacy)

1. Job created → pending state, added to `ci_pending_builds`
1. Runner requests job → job assigned to runner, transitioned to running, moved from `ci_pending_builds` to `ci_running_builds`
1. Runner executes job

#### New workflow (two-phase commit)

1. Job created → pending state, added to `ci_pending_builds`
1. Runner requests job → job assigned to runner, remains pending, removed from `ci_pending_builds` and added to Redis cache
1. Runner performs preparation tasks
1. Runner sends keep-alive signals (optional) and GitLab checks against Redis cache
1. Runner signals acceptance → job transitioned to running (entry created in `ci_running_builds`)
1. Runner executes job

## Implementation details

### Runner feature detection

Runners that support two-phase commit must include the feature in their capabilities:

```json
{
  "info": {
    "features": {
      "two_phase_job_commit": true
    }
  }
}
```

### API endpoints

#### Job request (modified)

- **Endpoint**: `POST /api/v4/jobs/request`
- **Behavior**:
  - For runners with `two_phase_job_commit`: Job assigned but remains `pending`
  - For legacy runners: Job assigned and transitioned to `running` (unchanged)

#### Job status update (modified)

- **Endpoint**: `PUT /api/v4/jobs/:id`
- **Parameters**:
  - `token`: Job authentication token
  - `state`: Job state - for two-phase commit workflow, supports `pending` (keep-alive) and `running` (ready to start)
- **Behavior**:
  - `state=pending`: Keep-alive signal during preparation (returns `200 OK`)
  - `state=running`: Runner ready to start execution (transitions job to running)
  - Other states: Regular job completion (success, failed, etc.)
- **Responses**:
  - `200 OK`: Status updated successfully
  - `409 Conflict`: Job not in expected state for running transition
  - `400 Bad Request`: Invalid parameters

### Database changes

No database schema changes are required. The implementation uses existing fields and state transitions.

### State management

#### Job states

- **pending**: Job is waiting for runner or runner is preparing
- **running**: Job is actively being executed by runner
- **Other states**: Unchanged

#### Queue management

- Jobs are removed from `ci_pending_builds` when assigned to a runner (both workflows)
- For two-phase commit: Job remains `pending` until runner acceptance or a timeout
- For legacy: Job transitions to `running` immediately

## Backward compatibility

The feature is fully backward compatible:

- Legacy runners continue to work with the existing workflow
- New runners can opt-in to two-phase commit by declaring the feature
- No changes required for existing GitLab installations

### GitLab configuration

No configuration changes are required. The feature is automatically available when runners declare support for it.

## Monitoring and observability

### Metrics

- Existing job timing metrics remain unchanged
- New metrics may be added for preparation time tracking
- Runner heartbeat metrics continue to work

### Logging

- Job assignment events are logged with two-phase commit context
- Runner provisioning status updates are logged
- Existing job execution logs are unchanged

## Testing

The feature includes comprehensive test coverage:

- Unit tests for service logic
- API endpoint tests
- Integration tests for full workflow
- Backward compatibility tests

## Future enhancements

While not implemented in the initial version, the two-phase commit foundation enables:

1. **Job Declination**: Runners could decline jobs they cannot execute
1. **Timeout Handling**: Automatic job reassignment if runners don't accept within a timeout
1. **Smart Routing**: Router daemons could use the two-phase commit for more efficient job distribution
1. **Preparation Time Tracking**: Separate tracking of preparation vs. execution time

## Security considerations

- Job tokens remain valid during the preparation phase
- Runner authentication is required for all provisioning status updates
- No additional security risks are introduced

## Performance impact

- Minimal performance impact on existing workflows
- Slight reduction in database load due to fewer state transitions for two-phase commit jobs
- No impact on job execution performance

## Migration path

1. **Phase 1**: Deploy GitLab with two-phase commit support (backward compatible)
1. **Phase 2**: Update runners to support two-phase commit feature
1. **Phase 3**: Monitor and optimize based on usage patterns

No forced migration is required - runners can adopt the feature at their own pace.
