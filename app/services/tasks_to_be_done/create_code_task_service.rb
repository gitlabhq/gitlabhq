# frozen_string_literal: true

module TasksToBeDone
  class CreateCodeTaskService < BaseService
    protected

    def title
      'Create or import your code into your Project (Repository)'
    end

    def description
      <<~DESCRIPTION
        You've already created your Group and Project within GitLab; we'll quickly review this hierarchy below. Once you're within your project you can easily create or import repositories.

        **With GitLab Groups, you can:**

        * Create one or multiple Projects for hosting your codebase (repositories).
        * Assemble related projects together.
        * Grant members access to several projects at once.

        Groups can also be nested in subgroups.

        Read more about groups in our [documentation](https://docs.gitlab.com/ee/user/group/).

        **Within GitLab Projects, you can**

        * Use it as an issue tracker.
        * Collaborate on code.
        * Continuously build, test, and deploy your app with built-in GitLab CI/CD.

        You can also import an existing repository by providing the Git URL.

        * :book: [Read the documentation](https://docs.gitlab.com/ee/user/project/index.html).

        ## Next steps

        Create or import your first repository into the project you created:

        * [ ] Click **Projects** in the top navigation bar, then click **Your projects**.
        * [ ] Select the Project that you created, then select **Repository**.
        * [ ] Once on the Repository page you can select the **+** icon to add or import files.
        * [ ] You can review our full documentation on creating [repositories](https://docs.gitlab.com/ee/user/project/repository/) in GitLab.

        :tada: All done, you can close this issue!
      DESCRIPTION
    end

    def label_suffix
      'code'
    end
  end
end
