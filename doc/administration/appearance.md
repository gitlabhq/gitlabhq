---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Appearance

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

You can update your settings to change the look and feel of your GitLab self-managed instance.

To open the **Appearance** settings:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > Appearance**.

## Customize your homepage button

Customize the appearance of your **Homepage** button.

The **Homepage** button is located on the upper-left corner of the left sidebar.
Replace the default **GitLab logo** **{tanuki}** with any image.

- The file should be less than 1 MB.
- The image should be 28 pixels high. Images more than 28 px high will be resized.

To customize your **Homepage** icon image:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > Appearance**.
1. Under **Navigation bar**, select **Choose file**.
1. At the bottom of the page, select **Update appearance settings**.

Pipeline status emails also show your custom logo. However, some email applications do not support SVG images. If your custom image is in SVG format, pipeline emails show the default logo.

## Customize the favicon

Customize the appearance of the favicon. A favicon is the icon for a website that shows in your browser tabs. The **GitLab logo** **{tanuki}** is the default browser and CI/CD status favicon. Replace the default icon with any image that is `32 x 32` pixels and in `.png` or `.ico` format.

To change the favicon:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > Appearance**.
1. Under **Favicon**, select **Choose file**.
1. At the bottom of the page, select **Update appearance settings**.

## Add system header and footer messages

> - **Enable header and footer in emails** checkbox [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/344819) in GitLab 15.9.

Add a small header message, a small footer message, or both, to the interface of your GitLab instance. These messages show on all projects and pages of the instance, such as the sign-in and register pages.

- You can italicize, bold, or add links to your message with Markdown.
- Markdown lists, images, and quotes are not supported because system messages must be a single line.

To add a system header, footer message, or both:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > Appearance**.
1. Go to the **System header and footer** section.
1. Complete the fields.
1. Optional. Select the **Enable header and footer in emails** checkbox. Add your system messages to all emails sent by your GitLab instance.
1. At the bottom of the page, select **Update appearance settings**.

By default, the system header and footer text is white text on an orange background. To customize the message colors:

- Go to the **System header and footer** section and select **Customize colors**.

## Customize your sign-in and register pages

Customize the title, description, and logo on the sign-in and register page. By default, the register page logo is located on the left of the page, between the title and the description.

To customize your sign-in and register page titles or descriptions:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > Appearance**.
1. Go to the **Sign in/Sign up pages** section.
1. Complete the fields. You can format the page **Title** and **Description** with Markdown.
1. At the bottom of the page, select **Update appearance settings**.

To customize the logo on your sign-in and register pages:

- The file should be less than 1 MB.
- The image should be 128 pixels high. Images more than 128 px high will be resized.

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > Appearance**.
1. Go to the **Sign in/Sign up pages** section.
1. Under **Logo**, select **Choose file**.
1. At the bottom of the page, select **Update appearance settings**.

You can add also add a [customized help message](settings/help_page.md) below the sign-in message or add [a sign-in text message](settings/sign_in_restrictions.md#sign-in-information).

### Disable cookie-based language selector

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144484) in GitLab 16.10.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available, an administrator can [enable the feature flag](feature_flags.md) named `disable_preferred_language_cookie`.
On GitLab.com and GitLab Dedicated, this feature is not available.

You can remove the cookie-based language selector from the footer of the sign-in and register pages by enabling the `disable_preferred_language_cookie` feature flag.

## Customize the Progressive Web App

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/375708) in GitLab 15.9.

Customize the icon, display name, short name, and description for your Progessive Web App (PWA). For more information, see [Progressive Web App](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps).

To add a Progressive Web App name and short name:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > Appearance**.
1. Go to the **Progressive Web App (PWA)** section.
1. Complete the fields.
   - **Name** is the display name of your PWA.
   - **Short name** shows on mobile devices and small screens.
1. At the bottom of the page, select **Update appearance settings**.

To add a Progressive Web App description:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > Appearance**.
1. Go to the **Progressive Web App (PWA)** section.
1. Complete the fields. You can format the **Description** with Markdown.
1. At the bottom of the page, select **Update appearance settings**.

To customize your Progressive Web App icon:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > Appearance**.
1. Go to the **Progressive Web App (PWA)** section.
1. Under **Icon**, select **Choose file**.
1. At the bottom of the page, select **Update appearance settings**.

## Member guidelines

You can add member guidelines to the group and project member pages in GitLab.
You can use [Markdown](../user/markdown.md) in the description.

The member guidelines are visible to users who have the [permission](../user/permissions.md) to manage either:

- Group members at the group level.
- Project members at the project level.

You should add member guidelines if you manage group and project membership using either:

- Predefined groups instead of on an individual basis.
- External tooling.

## Add guidelines to the new project page

Add a guideline message to the **New project page**. You can format your message with Markdown. The guideline message shows under the **New Project** message and, on the left side of the **New project page**.

To add a guideline message to the **New project page**:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > Appearance**.
1. Go to the **New project pages** section.
1. Complete the fields. You can format your guidelines with Markdown.

## Add profile image guidelines

Add guidelines for profile images.

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > Appearance**.
1. Go to the **Profile image guideline** section.
1. Complete the fields. You can format your text with Markdown.

## Libravatar

GitLab supports [Libravatar](https://www.libravatar.org) is for avatar images, but you must manually enable Libravatar support on the GitLab instance. For more information, see [Libravatar](../administration/libravatar.md) to use the service.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
