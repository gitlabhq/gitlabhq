# Users Permissions

GitLab CI relies on user's role on the GitLab. There are three permissions levels on GitLab CI: admin, master, developer, other.

Admin user can perform any actions on GitLab CI in scope of instance and project. Also user with admin permission can use admin interface.




| Action                                | Guest, Reporter | Developer   | Master   | Admin  |
|---------------------------------------|-----------------|-------------|----------|--------|
| See commits and builds                | ✓               | ✓           | ✓        | ✓      |
| Retry or cancel build                 |                 | ✓           | ✓        | ✓      |
| Remove project                        |                 |             | ✓        | ✓      |
| Create project                        |                 |             | ✓        | ✓      |
| Change project configuration          |                 |             | ✓        | ✓      |
| Add specific runners                  |                 |             | ✓        | ✓      |
| Add shared runners                    |                 |             |          | ✓      |
| See events in the system              |                 |             |          | ✓      |
| Admin interface                       |                 |             |          | ✓      |




