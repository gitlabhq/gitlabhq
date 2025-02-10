---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: AWS CodePipeline
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com

> - [Introduced](https://gitlab.com/gitlab-com/alliances/aws/wip/aws-cs-collab/aws-gitlab-collaboration/-/issues/25) in GitLab 16.5.

You can use your GitLab project to build, test, and deploy code changes using [AWS CodePipeline](https://aws.amazon.com/codepipeline/). To do so, you use:

- AWS CodeStar Connections to connect your GitLab.com account to AWS.
- That connection to automatically start a pipeline based on changes to your code.

## Create a connection from AWS CodePipeline to GitLab

Prerequisites:

- You must have the Owner role on the GitLab project that you are connecting with AWS CodePipeline.
- You must have the appropriate permissions to create a connection in AWS.
- You must use a supported AWS region. Unsupported regions (also listed in the [AWS documentation](https://docs.aws.amazon.com/codepipeline/latest/userguide/connections-gitlab.html)) are:
  - Asia Pacific (Hong Kong).
  - Africa (Cape Town).
  - Middle East (Bahrain).
  - Europe (Zurich).
  - AWS GovCloud (US-West and US-East).

To create a connection to a project on GitLab.com, you can use either the AWS Management Console, or the AWS Command Line Interface (AWS CLI).

### Use the AWS Management Console

To connect a new or existing pipeline in AWS CodePipeline with GitLab.com, first authorize the AWS connection to use your GitLab account.

1. Sign in to the AWS Management Console, and open the [AWS Developer Tools console](https://console.aws.amazon.com/codesuite/settings/connections).
1. Select **Settings** > **Connections** > **Create connection**.
1. In **Select a provider**, select **GitLab**.
1. In **Connection name**, enter the name for the connection that you want to create and select **Connect to GitLab**.
1. In the GitLab sign-in page, enter your credentials and select **Sign in**.
1. An authorization page displays with a message requesting authorization for the connection to access your GitLab account. Select **Authorize**.
1. The browser returns to the connections console page. In the **Create GitLab connection** section, the new connection is shown in **Connection name**.
1. Select **Connect to GitLab**. After the connection is created successfully, a success banner displays. The connection details are shown on the **Connection settings** page.

Now you've connected AWS CodeSuite to GitLab.com, you can create or edit a pipeline in AWS CodePipeline that leverages your GitLab projects.

1. Sign in to the [AWS CodePipeline console](https://console.aws.amazon.com/codesuite/codepipeline/start).
1. Create or edit a pipeline:
   - If you are creating a pipeline:
     - Complete the fields in the first screen and select **Next**.
     - On the **Source** page, in the **Source Provider** section, select **GitLab**.
   - If you are editing an existing pipeline:
     - Select **Edit** > **Edit stage** to add or edit your source action.
     - On the **Edit action** page, in the **Action name** section, enter the name for your action.
     - In **Action provider**, select **GitLab**.
1. In **Connection**, select the connection you created earlier.
1. In **Repository name**, to choose the name of your GitLab project, specify the full project path with the namespace and all subgroups.
   For example, for a group-level project, enter the project name in the following format: `group-name/subgroup-name/project-name`.
   The project path with the namespace is in the URL in GitLab. Do not copy URLs from the Web IDE or raw views as they contain other special URL segments.
   You can also pick an option from the dialog, or type a new path manually.
   For more information about the:
   - Path and namespace, see the `path_with_namespace` field in the [projects API](../../../api/projects.md#get-a-single-project).
   - Namespace in GitLab, see [namespaces](../../namespace/_index.md).

1. In **Branch name**, select the branch where you want your pipeline to detect source changes.
   If the branch name does not populate automatically, this might be because of one of the following:
   - You do not have the Owner role for the project.
   - The project name is not valid.
   - The connection used does not have access to the project.

1. In **Output artifact format**, select the format for your artifacts. To store:
   - Output artifacts from the GitLab action using the default method, select **CodePipeline default**. The action accesses the files from the GitLab repository and
     stores the artifacts in a ZIP file in the pipeline artifact store.
   - A JSON file that contains a URL reference to the repository so that downstream actions can perform Git commands directly, select **Full clone**. This option can only be used
     by CodeBuild downstream actions. To choose this option:
     - [Update the permissions for your CodeBuild project service role](https://docs.aws.amazon.com/codepipeline/latest/userguide/troubleshooting.html#codebuild-role-connections).
     - Follow the [AWS CodePipeline tutorial on how to use full clone with a GitHub pipeline source](https://docs.aws.amazon.com/codepipeline/latest/userguide/tutorials-github-gitclone.html).
1. Save the source action and continue.

### Use the AWS CLI

To use the AWS CLI to create a connection:

- Use the `create-connection` command.
- Go to the AWS Console to authenticate with your GitLab.com account.
- Connect your GitLab project to AWS CodePipeline.

To use the `create-connection` command:

1. Open a terminal (Linux, macOS, or Unix) or command prompt (Windows). Use the AWS CLI to run the `create-connection` command,
   specifying the `--provider-type` and `--connection-name` for your connection. In this example, the third-party provider name is
   `GitLab` and the specified connection name is `MyConnection`.

   ```shell
   aws codestar-connections create-connection --provider-type GitLab --connection-name MyConnection
   ```

   If successful, this command returns the connection's Amazon Resource Name (ARN) information. For example:

   ```json
   {
   "ConnectionArn": "arn:aws:codestar-connections:us-west-2:account_id:connection/aEXAMPLE-8aad-4d5d-8878-dfcab0bc441f"
   }
   ```

1. The new connection is created with a `PENDING` status by default. Use the console to change the connection's status to `AVAILABLE`.

1. [Use the AWS Console to complete the connection](#use-the-aws-management-console). Make sure you select your pending GitLab connection. Do not select **Create connection**.

## Related topics

- [Announcement that AWS CodePipeline supports GitLab](https://aws.amazon.com/about-aws/whats-new/2023/08/aws-codepipeline-supports-gitlab/)
- [GitLab connections - AWS CodePipeline](https://docs.aws.amazon.com/codepipeline/latest/userguide/connections-gitlab.html)
- [Create a connection to GitLab - Developer Tools console](https://docs.aws.amazon.com/dtconsole/latest/userguide/connections-create-gitlab.html)
- [CodeStarSourceConnection for Bitbucket, GitHub, GitHub Enterprise Server, and GitLab actions - AWS CodePipeline](https://docs.aws.amazon.com/codepipeline/latest/userguide/action-reference-CodestarConnectionSource.html)
