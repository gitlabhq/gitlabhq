---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# IBM Engineering Workflow Management (EWM) Integration **(CORE)**

This service allows you to navigate from GitLab to EWM work items mentioned in merge request descriptions and commit messages. Each work item reference is automatically converted to a link back to the work item.

NOTE: **Note:**
This IBM product was [formerly named Rational Team Concert](https://jazz.net/blog/index.php/2019/04/23/renaming-the-ibm-continuous-engineering-portfolio/)(RTC). This integration is also compatible with all versions of RTC and EWM.

1. From a GitLab project, navigate to **Settings > Integrations**, and then click **EWM**.
1. Enter the information listed below.

   | Field | Description |
   | ----- | ----------- |
   | `project_url` | URL of the EWM project area to link to the GitLab project. To obtain your project area URL, navigate to the path `/ccm/web/projects` and copy the listed project's URL. For example, `https://example.com/ccm/web/Example%20Project` |
   | `issues_url` | URL to the work item editor in the EWM project area. The format is `<your-server-url>/resource/itemName/com.ibm.team.workitem.WorkItem/:id`. For example, `https://example.com/ccm/resource/itemName/com.ibm.team.workitem.WorkItem/:id` |
   | `new_issue_url` | URL to create a new work item in the EWM project area. Append the following fragment to your project area URL: `#action=com.ibm.team.workitem.newWorkItem`. For example, `https://example.com/ccm/web/projects/JKE%20Banking#action=com.ibm.team.workitem.newWorkItem` |

## Reference EWM work items in commit messages

You can use any of the keywords supported by the EWM Git Integration Toolkit to refer to work items. Work items can be referenced using the format: `<keyword> <id>`.

You can use the following keywords:

- `bug`
- `task`
- `defect`
- `rtcwi`
- `workitem`
- `work item`

For more details, see the EWM documentation page [Creating links from commit comments](https://www.ibm.com/support/knowledgecenter/SSYMRC_7.0.0/com.ibm.team.connector.cq.doc/topics/t_creating_links_through_comments.html), which recommends against using the additionally-supported keyword `#` because of incompatibility with GitLab.
