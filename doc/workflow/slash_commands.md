# GitLab slash commands

Slash commands are textual shortcuts for common actions on issues or merge
requests that are usually done by clicking buttons or dropdowns in GitLab's UI.
You can enter these commands while creating a new issue or merge request, and
in comments. Each command should be on a separate line in order to be properly
detected and executed.

Here is a list of all of the available commands and descriptions about what they
do.

| Command                    | Aliases             | Action       |
|:---------------------------|:--------------------|:-------------|
| `/close`                   | None                | Close the issue or merge request |
| `/open`                    | `/reopen`           | Reopen the issue or merge request |
| `/title <New title>`       | None                | Change title |
| `/assign @username`        | `/reassign`         | Assign |
| `/unassign`                | `/remove_assignee`  | Remove assignee |
| `/milestone %milestone`    | None                | Set milestone |
| `/clear_milestone`         | `/remove_milestone` | Remove milestone |
| `/label ~foo ~"bar baz"`   | `/labels`           | Add label(s) |
| `/unlabel ~foo ~"bar baz"` | `/remove_label`, `remove_labels` | Remove label(s) |
| `/clear_labels`            | `/clear_label`      | Clear all labels |
| `/todo`                    | None                | Add a todo |
| `/done`                    | None                | Mark todo as done |
| `/subscribe`               | None                | Subscribe |
| `/unsubscribe`             | None                | Unsubscribe |
| `/due_date <YYYY-MM-DD> | <N days>` | `/due`     | Set a due date |
| `/clear_due_date`          | None                | Remove due date |
