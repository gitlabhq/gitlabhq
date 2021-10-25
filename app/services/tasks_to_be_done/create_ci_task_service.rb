# frozen_string_literal: true

module TasksToBeDone
  class CreateCiTaskService < BaseService
    protected

    def title
      'Set up CI/CD'
    end

    def description
      <<~DESCRIPTION
        GitLab CI/CD is a tool built into GitLab for software development through the [continuous methodologies](https://docs.gitlab.com/ee/ci/introduction/index.html#introduction-to-cicd-methodologies):

        * Continuous Integration (CI)
        * Continuous Delivery (CD)
        * Continuous Deployment (CD)

        Continuous Integration works by pushing small changes to your application’s codebase hosted in a Git repository, and, to every push, run a pipeline of scripts to build, test, and validate the code changes before merging them into the main branch.

        Continuous Delivery and Deployment consist of a step further CI, deploying your application to production at every push to the default branch of the repository.

        These methodologies allow you to catch bugs and errors early in the development cycle, ensuring that all the code deployed to production complies with the code standards you established for your app.

        * :book: [Read the documentation](https://docs.gitlab.com/ee/ci/introduction/index.html)
        * :clapper: [Watch a Demo](https://www.youtube.com/watch?v=1iXFbchozdY)

        ## Next steps

        * [ ] To start we recommend reviewing the following documentation:
            * [ ] [How GitLab CI/CD works.](https://docs.gitlab.com/ee/ci/introduction/index.html#how-gitlab-cicd-works)
            * [ ] [Fundamental pipeline architectures.](https://docs.gitlab.com/ee/ci/pipelines/pipeline_architectures.html)
            * [ ] [GitLab CI/CD basic workflow.](https://docs.gitlab.com/ee/ci/introduction/index.html#basic-cicd-workflow)
            * [ ] [Step-by-step guide for writing .gitlab-ci.yml for the first time.](https://docs.gitlab.com/ee/user/project/pages/getting_started_part_four.html)
        * [ ] When you're ready select **Projects** (in the top navigation bar) > **Your projects** > select the Project you've already created.
        * [ ] Select **CI / CD** in the left navigation to start setting up CI / CD in your project.
      DESCRIPTION
    end

    def label_suffix
      'ci'
    end
  end
end
