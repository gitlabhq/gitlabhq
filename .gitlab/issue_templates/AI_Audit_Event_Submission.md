# AI Audit Event Submission Template

Use this template when requesting new audit events to be included in the Agentic Audit Event System.

**Reference:** [Audit Event Development Guidelines](https://docs.gitlab.com/development/audit_event_guide/)

---

## Overview

| Field | Value |
|-------|-------|
| **Feature/Agent Name** |  |
| **Owning Group** | _e.g., `~"group::compliance"`_ |
| **Target Milestone** |  |
| **Related Epics/Issues** |  |

_Brief description of what this agent or feature does and why audit events are needed._

---

## Events to Capture

_List each state change or action that should generate an audit event._

| Trigger | Event Name | Description of event |
|---------|------------|----------------------|
| _e.g., Agent created_ | `create_ai_catalog_agent` |  |
| _e.g., Agent updated_ | `update_ai_catalog_agent` |  |
| _e.g., Agent deleted_ | `delete_ai_catalog_agent` |  |
| _e.g., Agent enabled for project/group_ | `enable_ai_catalog_agent` |  |
| _e.g., Agent disabled_ | `disable_ai_catalog_agent` |  |

---

## Event Definitions

_For each event, provide the audit context details._

### Event: `[event_name]`

| Attribute | Value | Notes |
|-----------|-------|-------|
| **name** | `[event_name]` |  |
| **author** | `current_user` | User who performs the action |
| **scope** | `project` \| `group` \| `instance` \| `user` | Scope the event belongs to |
| **target** | `[target_object]` | Object being audited (e.g., agent) |
| **message** | See below | Primary message describing the action |
| **Saved to database** | Yes/No | High-volume events should be streaming-only. Expected event frequency: _e.g., \~100/day per instance_ |
| **Additional Considerations** |  | Privacy concerns, sensitive fields requiring hashing/exclusion |
| **Extra Details** |  | Any additional context or metadata to capture |

---

## Checklist

* [ ] Event names are unique, lowercase, and underscored
* [ ] Messages are descriptive and not translated
* [ ] Data volume considered (streaming-only if high volume)
* [ ] Related issues/MRs linked

/label  ~"section::sec" ~"group::compliance" ~"workflow::planning breakdown" ~"Category:Audit Events" 
/assign  @nrosandich, @khornergit
/epic https://gitlab.com/groups/gitlab-org/-/epics/20709

