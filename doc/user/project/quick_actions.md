# GitLab quick actions

Quick actions are textual shortcuts for common actions on issues or merge
requests that are usually done by clicking buttons or dropdowns in GitLab's UI.
You can enter these commands while creating a new issue or merge request, and
in comments. Each command should be on a separate line in order to be properly
detected and executed. The commands are removed from the issue, merge request or
comment body before it is saved and will not be visible to anyone else.

Below is a list of all of the available commands and descriptions about what they
do.

| Command                    | Action       |
|:---------------------------|:-------------|
| `/close`                   | Close the issue or merge request |
| `/reopen`                  | Reopen the issue or merge request |
| `/merge`                   | Merge (when pipeline succeeds) |
| `/title <New title>`       | Change title |
| `/assign @username`        | Assign |
| `/unassign`                | Remove assignee |
| `/milestone %milestone`    | Set milestone |
| `/remove_milestone`        | Remove milestone |
| `/label ~foo ~"bar baz"`   | Add label(s) |
| `/unlabel ~foo ~"bar baz"` | Remove all or specific label(s) |
| `/relabel ~foo ~"bar baz"` | Replace all label(s) |
| `/todo`                    | Add a todo |
| `/done`                    | Mark todo as done |
| `/subscribe`               | Subscribe |
| `/unsubscribe`             | Unsubscribe |
| <code>/due &lt;in 2 days &#124; this Friday &#124; December 31st&gt;</code> | Set due date |
| `/remove_due_date`         | Remove due date |
| `/wip`                     | Toggle the Work In Progress status |
| <code>/estimate &lt;1w 3d 2h 14m&gt;</code> | Set time estimate |
| `/remove_estimate`       | Remove estimated time |
| <code>/spend &lt;time(1h 30m &#124; -1h 5m)&gt; &lt;date(YYYY-MM-DD)&gt;</code> | Add or subtract spent time; optionally, specify the date that time was spent on |
| `/remove_time_spent`       | Remove time spent |
| `/target_branch <Branch Name>` | Set target branch for current merge request |
| `/award :emoji:`  | Toggle award for :emoji: |
| `/board_move ~column`      | Move issue to column on the board |
| `/duplicate #issue`        | Closes this issue and marks it as a duplicate of another issue |
| `/move path/to/project`        | Moves issue to another project |
| `/tableflip`               | Append the comment with `(╯°□°)╯︵ ┻━┻` |
| `/shrug`                   | Append the comment with `¯\＿(ツ)＿/¯` |
| <code>/copy_metadata #issue &#124; !merge_request</code> | Copy labels and milestone from other issue or merge request |
