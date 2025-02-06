---
stage: Monitor
group: Platform Insights
info: For assistance with this tutorial, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
title: 'Tutorial: Set up product analytics in a GitLab Pages website project'
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed
**Status:** Experiment

Understanding how your users engage with your website or application is important for making data-driven decisions.
By identifying the most and least used features by your users, your team can decide where and how to spend their time effectively.

Follow along to learn how to set up an example website project, onboard product analytics for the project, instrument the website to start collecting events,
and use project-level analytics dashboards to understand user behavior.

Here's an overview of what we're going to do:

1. Create a project from a template
1. Onboard the project with product analytics
1. Instrument the website with tracking snippet
1. Collect usage data
1. View dashboards

## Before you begin

To follow along this tutorial, you must:

- [Enable product analytics](../../development/internal_analytics/product_analytics.md#enable-product-analytics) for your instance.
- Have the Owner role for the group you create the project in.

## Create a project from a template

First of all, you need to create a project in your group.

GitLab provides project templates,
which make it easier to set up a project with all the necessary files for various use cases.
Here, you'll create a project for a plain HTML website.

To create a project:

1. On the left sidebar, at the top, select **Create new** (**{plus}**) and **New project/repository**.
1. Select **Create from template**.
1. Select the **Pages/Plain HTML** template.
1. In the **Project name** text box, enter a name (for example `My website`).
1. From the **Project URL** dropdown list, select the group you want to create the project in.
1. In the **Project slug** text box, enter a slug for your project (for example, `my-website`).
1. Optional. In the **Project description** text box, enter a description of your project.
   For example, `Plain HTML website with product analytics`. You can add or edit this description at any time.
1. Under **Visibility Level**, select the desired level for the project.
   If you create the project in a group, the visibility setting for a project must be at least as restrictive as the visibility of its parent group.
1. Select **Create project**.

Now you have a project with all the files you need for a plain HTML website.

## Onboard the project with product analytics

To collect events and view dashboards about your website usage, the project must have product analytics onboarded.

To onboard your new project with product analytics:

1. In the project, select **Analyze > Analytics dashboards**.
1. Find the **Product analytics** item and select **Set up**.
1. Select **Set up product analytics**.
1. Wait for your instance to finish creating.
1. Copy the **HTML script setup** snippet. You will need it in the next steps.

Your project is now onboarded and ready for your application to start sending events.

## Instrument your website

To collect and send usage events to GitLab, you must include a code snippet in your website.
You can choose from several platform and technology-specific tracking SDKs to integrate with your application.
For this example website, we use the [Browser SDK](../../development/internal_analytics/browser_sdk.md).

To instrument your new website:

1. In the project, select **Code > Repository**.
1. Select the **Edit > Web IDE**.
1. In the left Web IDE toolbar, select **File Explorer** and open the `public/index.html` file.
1. In the `public/index.html` file, before the closing `</body>` tag, paste the snippet you copied in the previous section.

   The code in the `index.html` file should look like this (where `appId` and `host` have the values provided in the onboarding section):

   ```html
   <!DOCTYPE html>
   <html>
     <head>
       <meta charset="utf-8">
       <meta name="generator" content="GitLab Pages">
       <title>Plain HTML site using GitLab Pages</title>
       <link rel="stylesheet" href="style.css">
     </head>
     <body>
       <div class="navbar">
         <a href="https://pages.gitlab.io/plain-html/">Plain HTML Example</a>
         <a href="https://gitlab.com/pages/plain-html/">Repository</a>
         <a href="https://gitlab.com/pages/">Other Examples</a>
       </div>

       <h1>Hello World!</h1>

       <p>
         This is a simple plain-HTML website on GitLab Pages, without any fancy static site generator.
       </p>
       <script src="https://unpkg.com/@gitlab/application-sdk-browser/dist/gl-sdk.min.js"></script>
       <script>
         window.glClient = window.glSDK.glClientSDK({
           appId: 'YOUR_APP_ID',
           host: 'YOUR_HOST',
         });
       </script>
     </body>
   </html>
   ```

1. In the left Web IDE toolbar, select **Source Control**.
1. Enter a commit message, such as `Add GitLab product analytics tracking snippet`.
1. Select **Commit**, and if prompted to create a new branch or continue, select **Continue**. You can then close the Web IDE.
1. In the project, select **Build > Pipelines**.
   A pipeline is triggered from your recent commit. Wait for it to finish running and deploying your updated website.

## Collect usage data

After the instrumented website is deployed, events start being collected.

1. In the project, select **Deploy > Pages**.
1. To open the website, in **Access pages** select your unique URL.
1. To collect some page view events, refresh the page a few times.

## View dashboards

GitLab provides two product analytics dashboards by default: **Audience** and **Behavior**.
These dashboards become available after your project has received some events.

To view these dashboards:

1. In the project, select **Analyze > Dashboards**.
1. From the list of available dashboards, select **Audience** or **Behavior**.

That was it! Now you have a website project with product analytics, which help you collect and visualize data to understand your users' behavior, and make your team work more efficiently.
