---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# IBM Engineering Workflow Management (EWM) Integration **(FREE)**

This service allows you to go from GitLab to EWM work items mentioned in merge request
descriptions and commit messages.
Each work item reference is automatically converted to a link to the work item.

This IBM product was [formerly named Rational Team Concert](https://jazz.net/blog/index.php/2019/04/23/renaming-the-ibm-continuous-engineering-portfolio/)(RTC). This integration is compatible with all versions of RTC and EWM.

To enable the EWM integration, in a project:

1. Go to the [Integrations page](overview.md#accessing-integrations).
1. Select **EWM**.
1. Select the checkbox under **Enable integration**.
1. Fill in the required fields:

   - **Project URL**: The URL to the EWM project area.

     To obtain your project area URL, navigate to the
     path `/ccm/web/projects` and copy the listed project's URL. For example, `https://example.com/ccm/web/Example%20Project`.
   - **Issue URL**: The URL to the work item editor in the EWM project area.

     The format is `<your-server-url>/resource/itemName/com.ibm.team.workitem.WorkItem/:id`.
     GitLab replaces `:id` with the issue number
     (for example, `https://example.com/ccm/resource/itemName/com.ibm.team.workitem.WorkItem/:id`,
     which becomes `https://example.com/ccm/resource/itemName/com.ibm.team.workitem.WorkItem/123`).
   - **New issue URL**: URL to create a new work item in the EWM project area.

     Append the following fragment to your project area URL: `#action=com.ibm.team.workitem.newWorkItem`.
     For example, `https://example.com/ccm/web/projects/JKE%20Banking#action=com.ibm.team.workitem.newWorkItem`.

1. Select **Save changes** or optionally select **Test settings**.

## Reference EWM work items in commit messages

To refer to work items, you can use any keywords supported by the EWM Git Integration Toolkit.
Use the format: `<keyword> <id>`.

You can use the following keywords:

- `bug`
- `defect`
- `rtcwi`
- `task`
- `work item`
- `workitem`

Avoid using the keyword `#`. Learn more in the EWM documentation page
[Creating links from commit comments](https://www.ibm.com/docs/en/elm/7.0.0?topic=commits-creating-links-from-commit-comments).
