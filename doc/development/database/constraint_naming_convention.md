---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Constraints naming conventions
---

The most common option is to let Rails pick the name for database constraints and indexes or let
PostgreSQL use the defaults (when applicable). However, when defining custom names in Rails, or
working in Go applications where no ORM is used, it is important to follow strict naming conventions
to improve consistency and discoverability.

The table below describes the naming conventions for custom PostgreSQL constraints.
The intent is not to retroactively change names in existing databases but rather ensure consistency of future changes.

| Type                     | Syntax                                                                                            | Notes                                                                                                                                                                       | Examples                                                                                                          |
|--------------------------|---------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------|
| **Primary Key**          | `pk_<table name>`                                                                                 |                                                                                                                                                                             | `pk_projects`                                                                                                     |
| **Foreign Key**          | `fk_<table name>_<column name>[_and_<column name>]*_<foreign table name>`                         |                                                                                                                                                                             | `fk_projects_group_id_groups`                                                                                     |
| **Index**                | `index_<table name>_on_<column name>[_and_<column name>]*[_and_<column name in partial clause>]*` | Index names must be all lowercase. | `index_repositories_on_group_id`                                                                                  |
| **Unique Constraint**    | `unique_<table name>_<column name>[_and_<column name>]*`                                          |                                                                                                                                                                             | `unique_projects_group_id_and_name`                                                                               |
| **Check Constraint**     | `check_<table name>_<column name>[_and_<column name>]*[_<suffix>]?`                               | The optional suffix should denote the type of validation, such as `length` and `enum`. It can also be used to disambiguate multiple `CHECK` constraints on the same column. | `check_projects_name_length`<br />`check_projects_type_enum`<br />`check_projects_admin1_id_and_admin2_id_differ` |
| **Exclusion Constraint** | `excl_<table name>_<column name>[_and_<column name>]*_[_<suffix>]?`                               | The optional suffix should denote the type of exclusion being performed.                                                                                                    | `excl_reservations_start_at_end_at_no_overlap`                                                                    |

## Observations

- Check `db/structure.sql` for conflicts.
- Prefixes are preferred over suffices because they make it easier to identify the type of a given constraint quickly, as well as group them alphabetically;
- The `_and_` that joins column names can be omitted to keep the identifiers under the 63 characters' length limit defined by PostgreSQL. Additionally, the notation may be abbreviated to the best of our ability if struggling to keep under this limit.
- For indexes added to solve a very specific problem, it may make sense for the name to reflect their use.
