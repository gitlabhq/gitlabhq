# frozen_string_literal: true

module TasksToBeDone
  class CreateIssuesTaskService < BaseService
    protected

    def title
      'Create/import issues (tickets) to collaborate on ideas and plan work'
    end

    def description
      <<~DESCRIPTION
        Issues allow you and your team to discuss proposals before, and during, their implementation. They can be used for a variety of other purposes, customized to your needs and workflow.

        Issues are always associated with a specific project. If you have multiple projects in a group, you can view all the issues at the group level. [You can review our full Issue documentation here.](https://docs.gitlab.com/ee/user/project/issues/)

        If you have existing issues or equivalent tickets you can import them as long as they are formatted as a CSV file, [the import process is covered here](https://docs.gitlab.com/ee/user/project/issues/csv_import.html).

        **Common use cases include:**

        * Discussing the implementation of a new idea
        * Tracking tasks and work status
        * Accepting feature proposals, questions, support requests, or bug reports
        * Elaborating on new code implementations

        ## Next steps

        * [ ] Select **Projects** in the top navigation > **Your Projects** > select the Project you've already created.
        * [ ] Once you've selected that project, you can select **Issues** in the left navigation, then click **New issue**.
        * [ ] Fill in the title and description in the **New issue** page.
        * [ ] Click on **Create issue**.

        Pro tip: When you're in a group or project you can always utilize the **+** icon in the top navigation (located to the left of the search bar) to quickly create new issues.

        That's it! You can close this issue.
      DESCRIPTION
    end

    def label_suffix
      'issues'
    end
  end
end
