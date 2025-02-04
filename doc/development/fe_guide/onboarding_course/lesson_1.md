---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Lesson 1
---

<div class="video-fallback">
  See the video: <a href="https://www.youtube.com/watch?v=k4C3-FKvZyI">Lesson 1 intro</a>.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/k4C3-FKvZyI" frameborder="0" allowfullscreen> </iframe>
</figure>

In this lesson you tackle the smallest of problems - a one-character text change. To do so, we have to learn:

- How to set up a GitLab Development Environment.
- How to navigate the GitLab code base.
- How to create a merge request in the GitLab project.

After we have learned these 3 things, a GitLab team member will do a live coding demo.
In the demo, they'll use each of the things learned by completing one of these small issues, so that you can complete an issue by yourself.

There is a list of issues that are very similar to the one we'll be live coding [here in the "Linked items" section](https://gitlab.com/gitlab-org/gitlab/-/issues/389920), it would be worth commenting on one of these now to get yourself assigned to one so that you can follow along.

## What is the GDK?

<div class="video-fallback">
  See the video: <a href="https://www.youtube.com/watch?v=qXGXshfo934">What is the GDK</a>?
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/qXGXshfo934" frameborder="0" allowfullscreen> </iframe>
</figure>

The GDK (GitLab Development Kit) is a local instance of GitLab that allows developers to run and test GitLab on their own computers.
Unlike frontend only applications, the GDK runs the entire GitLab application, including the back-end services, APIs, and a local database.
This allows developers to make changes, test them in real-time, and validate their modifications.

Tips for using the GDK:

- Troubleshooting documentation: When encountering issues with the GDK, refer to the troubleshooting documentation in the [GDK repository](https://gitlab.com/gitlab-org/gitlab-development-kit/-/tree/main/doc/troubleshooting).
  These resources provide useful commands and tips to help resolve common problems.
- Using the Rails console: The Rails console is an essential tool for interacting with your local instance of GitLab.
  You can access it by running `gdk rails c` and use it to enable or disable feature flags, perform backend operations, and more.
- Stay updated: Regularly update your GDK by running `gdk update`.
  This command fetches the latest branch of the GitLab project, as well as the latest branch of the GDK and its dependencies.
  Keeping your GDK up to date helps ensure you will be working with the latest version of GitLab and make sure you have the latest bug fixes.

Remember, if you need further assistance or have specific questions, you can reach out to the GitLab community through our [Discord](https://discord.com/invite/gitlab) or [other available support channels](https://about.gitlab.com/community/contribute/).

## Installing and using the GDK locally

<div class="video-fallback">
  See the video: <a href="https://www.youtube.com/watch?v=fcOyjuCizmY">Installing the GDK</a>.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/fcOyjuCizmY" frameborder="0" allowfullscreen> </iframe>
</figure>

For the latest installation instructions, refer to the [GitLab Development Kit documentation](https://gitlab.com/gitlab-org/gitlab-development-kit#installation).

Here's a step-by-step summary:

1. Prerequisites:
   - 16 GB RAM. If you have less, consider [using Gitpod](#using-gitpod-instead-of-running-the-gdk-locally)
   - Ensure that Git is installed on your machine.
   - Install a code editor, such as Visual Studio Code.
   - [Create an account](https://gitlab.com/users/sign_up) or [sign in](https://gitlab.com/users/sign_in) on GitLab.com and join the [community members group](https://gitlab.com/gitlab-community/meta#request-access-to-community-forks).
1. Installation:
   - Choose a directory to install the GitLab Development Kit (GDK).
   - Open your terminal and go to the chosen directory.
   - Download and run the installation script from the terminal:

     ```shell
     curl "https://gitlab.com/gitlab-org/gitlab-development-kit/-/raw/main/support/install" | bash
     ```

   - Only run scripts from trusted sources to ensure your safety.
   - The installation process may take around 20 minutes or more.
1. Choosing the repository:
   - Instead of cloning the main GitLab repository, use the community fork recommended for wider community members.
   - Follow the instructions provided to install the community fork.
1. GDK structure:
   - After the installation, the GDK directory is created.
   - Inside the GDK directory, you'll find the GitLab project folder.
1. Working with the GDK:
   - GDK offers lots of commands you can use to interact with your installation. To run those commands you must be inside the GDK or GitLab folder.
   - To start the GDK, run the command `gdk start` in your terminal.
   - You can explore available commands and options by running `gdk help` in the terminal.

Remember to consult the documentation or seek community support if you have any further questions or issues.

## Using Gitpod instead of running the GDK locally

<div class="video-fallback">
  See the video: <a href="https://www.youtube.com/watch?v=RI2kM5_oii4">Using Gitpod with GitLab</a>.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/RI2kM5_oii4" frameborder="0" allowfullscreen> </iframe>
</figure>

Gitpod is a service that allows you to run a virtual machine, specifically the GitLab Development Kit (GDK), on the Gitpod server instead of running it on your own machine.
It provides a web-based Integrated Development Environment (IDE) where you can edit code and see the GDK in action.
Gitpod is useful for quickly getting a GDK environment up and running, for making small merge requests without installing the GDK locally, or for running GDK on a machine that may not have enough resources.

To use Gitpod:

1. [Request access to the GitLab community forks](https://gitlab.com/groups/gitlab-community/community-members/-/group_members/request_access).
   Alternatively, you can create your own public fork, but will miss out on [the benefits of the community forks](https://gitlab.com/gitlab-community/meta#why).
1. Go to the [GitLab community fork website](https://gitlab.com/gitlab-community/gitlab), select **Edit**, then select **Gitpod**.
1. Configure your settings, such as the editor (VS Code desktop or browser) and the context (usually the `main` or `master` branch).
1. Select **Open** to create your Gitpod workspace. This process may take up to 20 minutes. The GitLab Development Kit (GDK) will be installed in the Gitpod workspace. This installation is faster than downloading and installing the full GDK locally.

After the workspace is created, you'll find your chosen IDE running in your browser. You can also connect it to your desktop IDE if preferred.
Treat Gitpod just like you would use VS Code locally. Create branches, make code changes, commit them, and push them back to the community fork.

Other tips:

- Remember to push your code regularly to avoid the workspace timing out. Idle workspaces are eventually destroyed.
- Customize your Gitpod workspace settings if needed, such as making your instance of GitLab frontend publicly available.
- If you run out of minutes, contact the support team on the Discord server.
- Troubleshoot issues by using commands like `gdk start` and `gdk status` in the Gitpod workspace as you would if it was running locally.

By following these steps, you can leverage Gitpod to efficiently develop with the GitLab Development Kit without the need for local installation.

## Navigating the GitLab codebase

<div class="video-fallback">
  See the video: <a href="https://www.youtube.com/watch?v=Wc5u879_0Aw">How to navigate the GitLab codebase</a>.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/Wc5u879_0Aw" frameborder="0" allowfullscreen> </iframe>
</figure>

Understanding how to navigate the GitLab codebase is essential for contributors.
Navigating the codebase and locating specific files can be challenging but crucial for making changes and addressing issues effectively.
Here we'll explore a step-by-step process for finding files and finding where they are rendered in GitLab.

If you already know the file you are going to work on and now you want to find where it is rendered:

1. Start by gathering clues to understand the file’s purpose. Look for relevant information within the file itself, such as keywords or specific content that might indicate its context.
1. You can also examine the file path (or folder structure) to gain insights into where the file might be rendered.
   A lot of routing in GitLab is very similar to the folder structure.
1. If you can work out which feature (or one of the features) that this component is used in, you can then leverage the GitLab user documentation to find out how to go to the feature page.
1. Follow the component hierarchy, do a global search for the filename to identify the parent component that renders the component.
   Continue to follow the hierarchy of components to trace back to a feature you recognize or can search for in the GitLab user docs.
1. You can use `git blame` with an extension like GitLens to find a recent MR where this file was changed.
   Most MR’s have a "How to validate" section that you can follow, if the MR doesn't have one, look for the previous change and until you find one that have validation steps.

If you know which page you need to fix and you want to find the file path, here are some things you can try:

- Look for content that is unique and doesn’t contain variables so that you can search for the translation variable.
- Try using Vue Dev Tools to find the component name.
- Look for unique identifiers like a `data-testid`,`id` or a unique looking CSS class in the HTML of the component and then search globally the codebase for those identifying strings.

## Writing a good merge request

<div class="video-fallback">
  See the video: <a href="https://www.youtube.com/watch?v=H5zozDNIn98">How to write a good MR</a>.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/H5zozDNIn98" frameborder="0" allowfullscreen> </iframe>
</figure>

When writing a merge request there are some important things to be aware of:

- Your MR will become a permanent part of the documentation of the GitLab project.
  It may be used in the future to help people understand why some code works the way it does and why it doesn't use an alternative solution.
- At least 2 other engineers are going to review your code. For the sake of efficiency (much like the code itself you have written) it is best to take a little while longer to get your MR right so that it is quicker and easier for others to read.
- The MRs that you create on GitLab are available to the public. This means you can add a link to MRs you are particularly proud of to your portfolio page when looking for a job.
- Since an MR is a technical document, you should try to implement a technical writing style.
  If you don’t know what that is, here is a highly recommended short course from [Google on Technical writing](https://developers.google.com/tech-writing/one).
  If you are also contributing to the documentation at GitLab, there is a [Technical Writing Fundamentals course available here from GitLab](https://handbook.gitlab.com/handbook/product/ux/technical-writing/fundamentals/).

## Live coding

<div class="video-fallback">
  See the video: <a href="https://www.youtube.com/watch?v=BJCCwc1Czt4">Lesson 1 code walkthrough</a>.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/BJCCwc1Czt4" frameborder="0" allowfullscreen> </iframe>
</figure>

Now it is your turn to complete your first MR, there is a list of issues that are very similar to the one we just finished that need completing [here in the "Linked items" section](https://gitlab.com/gitlab-org/gitlab/-/issues/389920). Thanks for contributing! (if there are none left, let us know on [Discord](https://discord.com/invite/gitlab) or [other available support channels](https://about.gitlab.com/community/contribute/) and we'll find more for you)
