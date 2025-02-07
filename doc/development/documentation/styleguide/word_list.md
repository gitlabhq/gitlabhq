---
stage: none
group: Documentation Guidelines
info: For assistance with this Style Guide page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
description: 'Writing styles, markup, formatting, and other standards for GitLab Documentation.'
title: Recommended word list
---

To help ensure consistency in the documentation, the Technical Writing team
recommends these word choices. In addition:

- The GitLab handbook contains a list of
  [top misused terms](https://handbook.gitlab.com/handbook/communication/top-misused-terms/).
- The documentation [style guide](../styleguide/_index.md#language) includes details
  about language and capitalization.
- The GitLab handbook provides guidance on the [use of third-party trademarks](https://handbook.gitlab.com/handbook/legal/policies/product-third-party-trademarks-guidelines/#process-for-adding-third-party-trademarks-to-gitlab).

For guidance not on this page, we defer to these style guides:

- [Microsoft Style Guide](https://learn.microsoft.com/en-us/style-guide/welcome/)
- [Google Developer Documentation Style Guide](https://developers.google.com/style)

<!-- vale off -->

<!-- Disable trailing punctuation in heading rule https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md#md026---trailing-punctuation-in-heading -->
<!-- markdownlint-disable MD026 -->

## `.gitlab-ci.yml` file

Use backticks and lowercase for **the `.gitlab-ci.yml` file**.

When possible, use the full phrase: **the `.gitlab-ci.yml` file**

Although users can specify another name for their CI/CD configuration file,
in most cases, use **the `.gitlab-ci.yml` file** instead.

## `&` (ampersand)

Do not use Latin abbreviations. Use **and** instead, unless you are documenting a UI element that uses an `&`.

## `@mention`

Try to avoid **`@mention`**. Say **mention** instead, and consider linking to the
[mentions topic](../../../user/discussions/_index.md#mentions).
Don't use backticks.

## 2FA, two-factor authentication

Spell out **two-factor authentication** in sentence case for the first use and in topic titles, and **2FA**
thereafter. If the first word in a sentence, do not capitalize `factor` or `authentication`. For example:

- Two-factor authentication (2FA) helps secure your account. Set up 2FA when you first sign in.

## ability, able

Try to avoid using **ability** or **able** because they can be ambiguous.
The usage of these words is similar to [allow and enable](#allow-enable).

Instead of talking about the abilities of the user, or
the capabilities of the product, be direct and specific.

You can, however, use these terms when you're talking about security, or
preventing someone from being able to complete a task in the UI.

Do not confuse **ability** or **able** with [permissions](#permissions) or [roles](#roles).

Use:

- You cannot change this setting.
- To change this setting, you must have the Maintainer role.
- Confirm you can sign in.
- The external load balancer cannot connect.
- Option to delete branches introduced in GitLab 17.1.

Instead of:

- You are not able to change this setting.
- You must have the ability to change this setting.
- Verify you are able to sign in.
- The external load balancer will not be able to connect.
- Ability to delete branches introduced in GitLab 17.1.

## above

Try to avoid using **above** when referring to an example or table in a documentation page. If required, use **previous** instead. For example:

- In the previous example, the dog had fleas.

Do not use **above** when referring to versions of the product. Use [**later**](#later) instead.

Use:

- In GitLab 14.4 and later...

Instead of:

- In GitLab 14.4 and above...
- In GitLab 14.4 and higher...
- In GitLab 14.4 and newer...

## access level

Access levels are different than [roles](#roles) or [permissions](#permissions).
When you create a user, you choose an access level: **Regular**, **Auditor**, or **Administrator**.

Capitalize these words when you refer to the UI. Otherwise use lowercase.

## add

Use **add** when an object already exists. If the object does not exist yet, use [**create**](#create) instead.
**Add** is the opposite of [remove](#remove).

For example:

- Add a user to the list.
- Add an issue to the epic.

Do not confuse **add** with [**create**](#create).

Do not use **Add new**.

## Admin area

Use:

- **Admin** area, to describe this area of the UI.
- **Admin** for the UI button.

Instead of:

- **Admin area** (with both words as bold)
- **Admin Area** (with **Area** capitalized)
- **Admin** Area (with Area capitalized)
- **administrator area**
- or other variants

## Admin Mode

Use title case for **Admin Mode**. The UI uses title case.

## administrator

Use **administrator access** instead of **admin** when talking about a user's access level.

![admin access level](img/admin_access_level_v15_9.png)

An **administrator** is not a [role](#roles) or [permission](#permissions).

Use:

- To do this thing, you must be an administrator.
- To do this thing, you must have administrator access.

Instead of:

- To do this thing, you must have the Admin role.

## advanced search

Use lowercase for **advanced search** to refer to the faster, more efficient search across the entire GitLab instance.

## agent

Use lowercase to refer to the [GitLab agent for Kubernetes](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent).
For example:

- To connect your cluster to GitLab, use the GitLab agent for Kubernetes.
- Install the agent in your cluster.
- Select an agent from the list.

Do not use title case for **GitLab Agent** or **GitLab Agent for Kubernetes**.

## agent access token

The token generated when you create an agent for Kubernetes. Use **agent access token**, not:

- registration token
- secret token
- authentication token

## agnostic

Instead of **agnostic**, use **platform-independent** or **vendor-neutral**.
([Vale](../testing/vale.md) rule: [`SubstitutionWarning.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab_base/SubstitutionWarning.yml))

## AI, artificial intelligence

Use **AI**. Do not spell out **artificial intelligence**.

## AI gateway

Use lowercase for **AI gateway** and do not hyphenate.

## AI Impact Dashboard

Use title case for **AI Impact Dashboard**.

On first mention on a page, use **GitLab Duo AI Impact Dashboard**.
Thereafter, use **AI Impact Dashboard** by itself.

## AI-powered DevSecOps platform

If preceded by GitLab, capitalize **Platform**. For example, the GitLab AI-powered DevSecOps Platform.

## air gap, air-gapped

Use **offline environment** to describe installations that have physical barriers or security policies that prevent or limit internet access. Do not use **air gap**, **air gapped**, or **air-gapped**. For example:

- The firewall policies in an offline environment prevent the computer from accessing the internet.

## allow, enable

Try to avoid **allow** and **enable**, unless you are talking about security-related features.

Use:

- You can add a file to your repository.

Instead of:

- This feature allows you to add a file to your repository.
- This feature enables users to add files to their repository.

This phrasing is more active and is from the user perspective, rather than the person who implemented the feature.
For more information, see the [Microsoft Style Guide](https://learn.microsoft.com/en-us/style-guide/a-z-word-list-term-collections/a/allow-allows).

## analytics

Use lowercase for **analytics** and its variations, like **contribution analytics** and **issue analytics**.
However, if the UI has different capitalization, make the documentation match the UI.

For example:

- You can view merge request analytics for a project. They are displayed on the Merge Request Analytics dashboard.

## ancestor

To refer to a [parent item](#parent) that's one or more level above in the hierarchy,
use **ancestor**.

Do not use **grandparent**.

Examples:

- An ancestor group, a group in the project's hierarchy.
- An ancestor epic, an epic in the issue's hierarchy.
- A group and all its ancestors.

See also: [child](#child), [descendant](#descendant), and [subgroup](#subgroup).

## and/or

Instead of **and/or**, use **or** or rewrite the sentence to spell out both options.

## and so on

Do not use **and so on**. Instead, be more specific. For more information, see the
[Microsoft Style Guide](https://learn.microsoft.com/en-us/style-guide/a-z-word-list-term-collections/a/and-so-on).

## area

Use [**section**](#section) instead of **area**. The only exception is [the **Admin** area](#admin-area).

## as

Do not use **as** to mean **because**.

Use:

- Because none of the endpoints return an ID...

Instead of:

- As none of the endpoints return an ID...

## as well as

Instead of **as well as**, use **and**.

## associate

Do not use **associate** when describing adding issues to epics, or users to issues, merge requests,
or epics.

Instead, use **assign**. For example:

- Assign the issue to an epic.
- Assign a user to the issue.

## authenticated user

Use **authenticated user** instead of other variations, like **signed in user** or **logged in user**.

## authenticate

Try to use the most suitable preposition when using **authenticate** as a verb.

Use **authenticate with** when referring to a system or provider that
performs the authentication, like a token or a service like OAuth.

For example:

- Authenticate with a deploy token.
- Authenticate with your credentials.
- Authenticate with OAuth.
- The runner uses an authentication token to authenticate with GitLab.

Use **authenticate against** when referring to a resource that contains
credentials that are checked for validation.

For example:

- The client authenticates against the LDAP directory.
- The script authenticates against the local user database.

## before you begin

Use **before you begin** when documenting the tasks that must be completed or the conditions that must be met before a user can complete a tutorial. Do not use **requirements** or **prerequisites**.

For more information, see [the tutorial page type](../topic_types/tutorial.md).

For task topic types, use [**prerequisites**](#prerequisites) instead.

## below

Try to avoid **below** when referring to an example or table in a documentation page. If required, use **following** instead. For example:

- In the following example, the dog has fleas.

## beta

Use lowercase for **beta**. For example:

- The feature is in beta.
- This is a beta feature.
- This beta release is ready to test.

You might also want to link to [this topic](../../../policy/development_stages_support.md#beta)
when writing about beta features.

## blacklist

Do not use **blacklist**. Another option is **denylist**. ([Vale](../testing/vale.md) rule: [`InclusiveLanguage.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab_base/InclusiveLanguage.yml))

## board

Use lowercase for **boards**, **issue boards**, and **epic boards**.

## box

Use **text box** to refer to the UI field. Do not use **field** or **box**. For example:

- In the **Variable name** text box, enter a value.

## branch

Use **branch** by itself to describe a branch. For specific branches, use these terms only:

- **default branch**: The primary branch in the repository. Users can use the UI to set the default
  branch. For examples that use the default branch, use `main` instead of [`master`](#master).
- **source branch**: The branch you're merging from.
- **target branch**: The branch you're merging to.
- **current branch**: The branch you have checked out.
  This branch might be the default branch, a branch you've created, a source branch, or some other branch.

Do not use the terms **feature branch** or **merge request branch**. Be as specific as possible. For example:

- The branch you have checked out...
- The branch you added commits to...

## bullet

Don't refer to individual items in an ordered or unordered list as **bullets**. Use **list item** instead. If you need to be less ambiguous, you can use:

- **Ordered list item** for items in an ordered list.
- **Unordered list item** for items in an unordered list.

## button

Don't use a descriptor with **button**.

Use:

- Select **Run pipelines**.

Instead of:

- Select the **Run pipelines** button.

## cannot, can not

Use **cannot** instead of **can not**.

See also [contractions](_index.md#contractions).

## card

Although the UI term might be **card**, do not use it in the documentation.
Avoid the descriptor if you can.

Use:

- By **Seat utilization**, select **Assign seats**.

Instead of:

- On the **Seat utilization** card, select **Assign seats**.

## Chat, GitLab Duo Chat

Use **Chat** with a capital `c` for **Chat** or **GitLab Duo Chat**.

On first use on a page, use **GitLab Duo Chat**.
Thereafter, use **Chat** by itself.

Do not use **Duo Chat**.

## checkbox

Use one word for **checkbox**. Do not use **check box**.

You **select** (not **check** or **enable**) and **clear** (not **deselect** or **disable**) checkboxes. For example:

- Select the **Protect environment** checkbox.
- Clear the **Protect environment** checkbox.

If you must refer to the checkbox, you can say it is selected or cleared. For example:

- Ensure the **Protect environment** checkbox is cleared.
- Ensure the **Protect environment** checkbox is selected.

(For `deselect`, [Vale](../testing/vale.md) rule: [`SubstitutionWarning.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab_base/SubstitutionWarning.yml))

## checkout, check out

Use **check out** as a verb. For the Git command, use `checkout`.

- Use `git checkout` to check out a branch locally.
- Check out the files you want to edit.

## cherry-pick, cherry pick

Use the hyphenated version of **cherry-pick**. Do not use **cherry pick**.

## CI, CD

When talking about GitLab features, use **CI/CD**. Do not use **CI** or **CD** alone.

## CI/CD

**CI/CD** is always uppercase. No need to spell it out on first use.

You can omit **CI/CD** when the context is clear, especially after the first use. For example:

- Test your code in a **CI/CD pipeline**. Configure the **pipeline** to run for merge requests.
- Store the value in a **CI/CD variable**. Set the **variable** to masked.

## CI/CD minutes

Do not use **CI/CD minutes**. This term was renamed to [**compute minutes**](#compute-minutes).

## child

Always use as a compound noun.

Examples:

- child issue
- child epic
- child objective
- child key result
- child pipeline

See also: [descendant](#descendant), [parent](#parent) and [subgroup](#subgroup).

## click

Do not use **click**. Instead, use **select** with buttons, links, menu items, and lists.
**Select** applies to more devices, while **click** is more specific to a mouse.

However, you can make an exception for **right-click** and **click-through demo**.

## cloud licensing

Do not use the phrase **cloud licensing**. Instead, focus on the fact
that this subscription is synchronized with GitLab.

For example:

- Your instance must be able to synchronize your subscription data with GitLab.

## cloud-native

When you're talking about using a Kubernetes cluster to host GitLab, you're talking about a **cloud-native version of GitLab**.
This version is different than the larger, more monolithic **Linux package** that is used to deploy GitLab.

You can also use **cloud-native GitLab** for short. It should be hyphenated and lowercase.

## code completion

Code Suggestions has evolved to include two primary features:

- **code completion**
- **code generation**

Use lowercase for **code completion**. Do not use **GitLab Duo Code Completion**.
GitLab Duo is reserved for Code Suggestions only.

**Code completion** must always be singular.

Example:

- Use code completion to populate the file.

## Code Explanation

Use title case for **Code Explanation**.

On first mention on a page, use **GitLab Duo Code Explanation**.
Thereafter, use **Code Explanation** by itself.

## code generation

Code Suggestions has evolved to include two primary features:

- **code completion**
- **code generation**

Use lowercase for **code generation**. Do not use **GitLab Duo Code Generation**.
GitLab Duo is reserved for Code Suggestions only.

**Code generation** must always be singular.

Examples:

- Use code generation to create code based on your comments.
- Adjust your code generation results by adding code comments to your file.

## Code Owner, code owner, `CODEOWNER`

Use **Code Owners** to refer to the feature name or concept. For example:

- Use the Code Owners approval rules to protect your code.

Use **code owner** or **code owners**, lowercase, to refer to a person or group with code ownership responsibilities.
For example:

- Assign a code owner to the project.
- Contact the code owner for a review.

Do not use **codeowner**, **CodeOwner**, or **code-owner**.

Use `CODEOWNERS`, uppercase and in backticks, to refer to the filename. For example:

- Edit the `CODEOWNERS` file to define the code ownership rules.

## Code Review Summary

Use title case for **Code Review Summary**.

On first mention on a page, use **GitLab Duo Code Review Summary**.
Thereafter, use **Code Review Summary** by itself.

## Code Suggestions

Use title case for **Code Suggestions**. On first mention on a page, use **GitLab Duo Code Suggestions**.

**Code Suggestions**, the feature, should always end in an `s`. However, write like it
is singular. For example:

- Code Suggestions is turned on for the instance.

When generically referring to the suggestions that the feature outputs, use lowercase.

Examples:

- Use Code Suggestions to display suggestions as you type. (This phrase describes the feature.)
- As you type, suggestions are displayed. (This phrase is generic.)

**Code Suggestions** has evolved to include two primary features:

- [**code completion**](#code-completion)
- [**code generation**](#code-generation)

## collapse

Use **collapse** instead of **close** when you are talking about expanding or collapsing a section in the UI.

## command line

Use **From the command line** to introduce commands.

Hyphenate when using as an adjective. For example, **a command-line tool**.

## compute

Use **compute** for the resources used by runners to run CI/CD jobs.

Related terms:

- [**compute minutes**](#compute-minutes): How compute usage is calculated. For example, `400 compute minutes`.
- [**compute quota**](../../../ci/pipelines/compute_minutes.md): The limit of compute minutes that a namespace can use each month.
- **compute usage**: The number of compute minutes that the namespace has used from the monthly quota.

## compute minutes

Use **compute minutes** instead of these (or similar) terms:

- **CI/CD minutes**
- **CI minutes**
- **pipeline minutes**
- **CI pipeline minutes**
- **pipeline minutes**

For more information, see [epic 2150](https://gitlab.com/groups/gitlab-com/-/epics/2150).

## configuration

When you edit a collection of settings, call it a **configuration**.

## configure

Use **configure** after a feature or product has been [set up](#setup-set-up).
For example:

1. Set up your installation.
1. Configure your installation.

## confirmation dialog

Use **confirmation dialog** to describe the dialog that asks you to confirm an action. For example:

- On the confirmation dialog, select **OK**.

Do not use **confirmation box** or **confirmation dialog box**. See also [**dialog**](#dialog).

## container registry

When documenting the GitLab container registry features and functionality, use lowercase.

Use:

- The GitLab container registry supports A, B, and C.
- You can push a Docker image to your project's container registry.

## create

Use **create** when an object does not exist and you are creating it for the first time.  **Create** is the opposite of [delete](#delete).

For example:

- Create an issue.

Do not confuse **create** with [**add**](#add).

Do not use **create new**. The word **create** implies that the object is new, and the extra word is not necessary.

## currently

Do not use **currently** when talking about the product or its features. The documentation describes the product as it is today.
([Vale](../testing/vale.md) rule: [`CurrentStatus.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab_base/CurrentStatus.yml))

## custom role

Use **custom role** when referring to a role created with specific customized permissions.

When referring to a non-custom role, use [**default role**](#default-role).

## data

Use **data** as a singular noun.

Use:

- Data is collected.
- The data shows a performance increase.

Instead of:

- Data are collected.
- The data show a performance increase.

## default role

Use **default role** when referring to the following predefined roles that have
no customized permissions added:

- Guest
- Planner
- Reporter
- Developer
- Maintainer
- Owner
- Minimal Access

Do not use **static role**, **built-in role**, or **predefined role**.

## delete

Use **delete** when an object is completely deleted. **Delete** is the opposite of [create](#create).

When the object continues to exist, use [**remove**](#remove) instead.
For example, you can remove an issue from an epic, but the issue still exists.

## Dependency Proxy

Use title case for the GitLab Dependency Proxy.

## deploy board

Use lowercase for **deploy board**.

## descendant

To refer to a [child item](#child) that's one or more level below in the hierarchy,
use **descendant**.

Do not use **grandchild**.

Examples:

- An descendant project, a project in the group's hierarchy.
- An descendant issue, an issue in the epic's hierarchy.
- A group and all its descendants.

See also: [ancestor](#ancestor), [child](#child), and [subgroup](#subgroup).

## Developer

When writing about the Developer role:

- Use a capital **D**.
- Write it out.
  - Use: if you are assigned the Developer role
  - Instead of: if you are a Developer

- When the Developer role is the minimum required role:
  - Use: at least the Developer role
  - Instead of: the Developer role or higher

Do not use bold.

Do not use **Developer permissions**. A user who is assigned the Developer role has a set of associated permissions.

## DevSecOps platform

If preceded by GitLab, capitalize **Platform**. For example, the GitLab DevSecOps Platform.

## dialog

Use **dialog** rather than any of these alternatives:

- **dialog box**
- **modal**
- **modal dialog**
- **modal window**
- **pop-up**
- **pop-up window**
- **window**

See also [**confirmation dialog**](#confirmation-dialog). For more information, see the [Microsoft Style Guide](https://learn.microsoft.com/en-us/style-guide/a-z-word-list-term-collections/d/dialog-box-dialog-dialogue).

Before using this term, confirm whether **dialog** or [**drawer**](#drawer) is
the correct term for your use case.

When the dialog is the location of an action, use **on** as a preposition. For example:

- On the **Grant permission** dialog, select **Group**.

See also [**on**](#on).

## disable

Do not use **disable** to describe making a setting or feature unavailable. Use alternatives like **turn off**, **hide**,
**make unavailable**, or **remove** instead.

To describe a state, use **off**, **inactive**, or **unavailable**.

This guidance is based on the
[Microsoft Style Guide](https://learn.microsoft.com/en-us/style-guide/a-z-word-list-term-collections/d/disable-disabled).

## disallow

Use **prevent** instead of **disallow**. ([Vale](../testing/vale.md) rule: [`Substitutions.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab_base/Substitutions.yml))

## Discussion Summary

Use title case for **Discussion Summary**.

On first mention on a page, use **GitLab Duo Discussion Summary**.
Thereafter, use **Discussion Summary** by itself.

## Docker-in-Docker, `dind`

Use **Docker-in-Docker** when you are describing running a Docker container by using the Docker executor.

Use `dind` in backticks to describe the container name: `docker:dind`. Otherwise, spell it out.

## downgrade

To be more upbeat and precise, do not use **downgrade**. Focus instead on the action the user is taking.

- For changing to earlier GitLab versions, use [**roll back**](#roll-back).
- For changing to lower GitLab tiers, use **change the subscription tier**.

## download

Use **download** to describe saving data to a user's device. For details, see
[the Microsoft style guide](https://learn.microsoft.com/en-us/style-guide/a-z-word-list-term-collections/d/download).

Do not confuse download with [export](#export).

## drawer

Use **drawer** to describe a [drawer UI component](../drawers.md) that:

- Appears from the right side of the screen.
- Displays context-specific information or actions without the user having to
  leave the current page.

To see examples of drawers:

- Go to the [Technical Writing Pipeline Editor](https://gitlab.com/gitlab-org/technical-writing/team-tasks/-/ci/editor?branch_name=main) and select **Help** (**{information-o}**).
- Open GitLab Duo Chat.

Before using this term, confirm whether **drawer** or [**dialog**](#dialog) is
the correct term for your use case.

## dropdown list

Use **dropdown list** to refer to the UI element. Do not use **dropdown** without **list** after it.
Do not use **drop-down** (hyphenated), **dropdown menu**, or other variants.

For example:

- From the **Visibility** dropdown list, select **Public**.

## earlier

Use **earlier** when talking about version numbers.

Use:

- In GitLab 14.1 and earlier.

Instead of:

- In GitLab 14.1 and lower.
- In GitLab 14.1 and older.

## easily

Do not use **easily**. If the user doesn't find the process to be easy, we lose their trust.

## edit

Use **edit** for UI documentation and user actions.

Use **update** for API documentation and programmatic changes.

For example:

- To edit your profile settings, select **Edit**.
- Use this endpoint to update user permissions.

## e.g.

Do not use Latin abbreviations. Use **for example**, **such as**, **for instance**, or **like** instead. ([Vale](../testing/vale.md) rule: [`LatinTerms.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab_base/LatinTerms.yml))

## ellipsis

When documenting UI text, if the UI includes an ellipsis, do not include the ellipsis in the documentation.
For more information, see the [Microsoft Style Guide](https://learn.microsoft.com/en-us/style-guide/punctuation/ellipses).

Use:

- **Create new**

Instead of:

- **Create new...**

## email

Do not use **e-mail** with a hyphen. When plural, use **emails** or **email messages**. ([Vale](../testing/vale.md) rule: [`SubstitutionWarning.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab_base/SubstitutionWarning.yml))

## email address

Use **email address** when referring to addresses used in emails. Do not shorten to **email**, which are messages.

## emoji

Use **emoji** to refer to the plural form of **emoji**.

## enable

Do not use **enable** to describe making a setting or feature available. Use **turn on** instead.

To describe a state, use **on** or **active**.

This guidance is based on the
[Microsoft Style Guide](https://learn.microsoft.com/en-us/style-guide/a-z-word-list-term-collections/d/disable-disabled).

## enter

In most cases, use **enter** rather than **type**.

- **Enter** encompasses multiple ways to enter information, including speech and keyboard.
- **Enter** assumes that the user puts a value in a field and then moves the cursor outside the field (or presses <kbd>Enter</kbd>).
  **Enter** includes both the entering of the content and the action to validate the content.

For example:

- In the **Variable name** text box, enter a value.
- In the **Variable name** text box, enter `my text`.

When you use **Enter** to refer to the key on a keyboard, use the HTML `<kbd>` tag:

- To view the list of results, press <kbd>Enter</kbd>.

See also [**type**](#type).

## epic

Use lowercase for **epic**.

See also [associate](#associate).

## epic board

Use lowercase for **epic board**.

## etc.

Try to avoid **etc.**. Be as specific as you can. Do not use
[**and so on**](#and-so-on) as a replacement.

Use:

- You can edit objects, like merge requests and issues.

Instead of:

- You can edit objects, like merge requests, issues, etc.

## expand

Use **expand** instead of **open** when you are talking about expanding or collapsing a section in the UI.

## experiment

Use lowercase for **experiment**. For example:

- This feature is an experiment.
- These features are experiments.
- This experiment is ready to test.

If you must, you can use **experimental**.

You might also want to link to [this topic](../../../policy/development_stages_support.md#experiment)
when writing about experimental features.

## export

Use **export** to indicate translating raw data,
which is not represented by a file in GitLab, into a standard file format.

You can differentiate **export** from **download** because:

- Often, you can use export options to change the output.
- Exported data is not necessarily downloaded to a user's device.

For example:

- Export the contents of your report to CSV format.

Do not confuse with [download](#download).

## FAQ

We want users to find information quickly, and they rarely search for the term **FAQ**.
Information in FAQs belongs with other similar information, under an easily searchable topic title.

## feature

You should rarely need to use the word **feature**. Instead, explain what GitLab does.
For example, use:

- Use merge requests to incorporate changes into the target branch.

Instead of:

- Use the merge request feature to incorporate changes into the target branch.

## feature branch

Do not use **feature branch**. See [branch](#branch).

## field

Use **text box** instead of **field** or **box**.

Use:

- In the **Variable name** text box, enter `my text`.

Instead of:

- In the **Variable name** field, enter `my text`.

However, you can make an exception when you are writing a task and you need to refer to all
of the fields at once. For example:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > CI/CD**.
1. Expand **General pipelines**.
1. Complete the fields.

Learn more about [documenting multiple fields at once](_index.md#documenting-multiple-fields-at-once).

## filename

Use one word for **filename**. When using filename as a variable, use `<filename>`.

([Vale](../testing/vale.md) rule: [`SubstitutionWarning.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab_base/SubstitutionWarning.yml))

## filter

When you are viewing a list of items, like issues or merge requests, you filter the list by
the available attributes. For example, you might filter by assignee or reviewer.

Filtering is different from [searching](#search).

## foo

Do not use **foo** in product documentation. You can use it in our API and contributor documentation, but try to use a clearer and more meaningful example instead.

## fork

A **fork** is a project that was created from a **upstream project** by using the
forking process.

The **upstream project** (also known as the **source project**) and the **fork** have a **fork relationship** and are
**linked**.

If the **fork relationship** is removed, the
**fork** is **unlinked** from the **upstream project**.

## Free

Use **Free**, in uppercase, for the subscription tier. When you refer to **Free**
in the context of other subscription tiers, follow [the subscription tier](#subscription-tier) guidance.

## full screen

Use two words for **full screen**.
([Vale](../testing/vale.md) rule: [`SubstitutionWarning.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab_base/SubstitutionWarning.yml))

## future tense

When possible, use present tense instead of future tense. For example, use **after you execute this command, GitLab displays the result** instead of **after you execute this command, GitLab will display the result**. ([Vale](../testing/vale.md) rule: [`FutureTense.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab_base/FutureTense.yml))

## GB, gigabytes

For **GB** and **MB**, follow the [Microsoft guidance](https://learn.microsoft.com/en-us/style-guide/a-z-word-list-term-collections/term-collections/bits-bytes-terms).

## Geo

Use title case for **Geo**.

## generally available, general availability

Use lowercase for **generally available** and **general availability**.
For example:

- This feature is generally available.

Use **generally available** more often. For example,
do not say:

- This feature has reached general availability.

Do not use **GA** to abbreviate general availability.

## GitLab

Do not make **GitLab** possessive (GitLab's). This guidance follows [GitLab Trademark Guidelines](https://handbook.gitlab.com/handbook/marketing/brand-and-product-marketing/brand/brand-activation/trademark-guidelines/).

Do not put **GitLab** next to the name of another third-party tool or brand.
For example, do not use:

- GitLab Chrome extension
- GitLab Kubernetes agent

Instead, use:

- GitLab extension for Chrome
- GitLab agent for Kubernetes

Putting the brand names next to each other can imply ownership or partnership, which we don't want to do,
unless we've gone through a legal review and have been told to promote the partnership.

This guidance follows the [Use of Third-party Trademarks](https://handbook.gitlab.com/handbook/legal/policies/product-third-party-trademarks-guidelines/#dos--donts-for-use-of-third-party-trademarks-in-gitlab).

## GitLab Dedicated

Use **GitLab Dedicated** to refer to the product offering. It refers to a GitLab instance that's hosted and managed by GitLab for customers.

GitLab Dedicated can be referred to as a single-tenant SaaS service.

Do not use **Dedicated** by itself. Always use **GitLab Dedicated**.

## GitLab Duo

Do not use **Duo** by itself. Always use **GitLab Duo**.

On first use on a page, use **GitLab Duo `<featurename>`**. As of Aug, 2024,
the following are the names of GitLab Duo features:

- GitLab Duo AI Impact Dashboard
- GitLab Duo Chat
- GitLab Duo Code Explanation
- GitLab Duo Code Review
- GitLab Duo Code Review Summary
- GitLab Duo Code Suggestions
- GitLab Duo for the CLI
- GitLab Duo Issue Description Generation
- GitLab Duo Issue Discussion Summary
- GitLab Duo Merge Commit Message Generation
- GitLab Duo Merge Request Summary
- GitLab Duo Product Analytics
- GitLab Duo Root Cause Analysis
- GitLab Duo Self-Hosted
- GitLab Duo Test Generation
- GitLab Duo Vulnerability Explanation
- GitLab Duo Vulnerability Resolution

Excluding GitLab Duo Self-Hosted, after the first use, use the feature name
without **GitLab Duo**.

## GitLab Duo Enterprise

Always use **GitLab Duo Enterprise** for the add-on. Do not use **Duo Enterprise** unless approved by legal.

You can use **the GitLab Duo Enterprise add-on** (with this capitalization) but you do not need to use **add-on**
and should leave it off when you can.

## GitLab Duo Pro

Always use **GitLab Duo Pro** for the add-on. Do not use **Duo Pro** unless approved by legal.

You can use **the GitLab Duo Pro add-on** (with this capitalization) but you do not need to use **add-on**
and should leave it off when you can.

## GitLab Duo Self-Hosted

When referring to the feature, always write **GitLab Duo Self-Hosted** in full
and in title case, unless you are
[referring to a language model that's hosted by a customer, rather than GitLab](#self-hosted-model).

Do not use **Self-Hosted** by itself.

## GitLab Duo Workflow

Use **GitLab Duo Workflow**. After first use, use **Workflow**.

Do not use **Duo Workflow** by itself.

## GitLab Flavored Markdown

When possible, spell out [**GitLab Flavored Markdown**](../../../user/markdown.md).

If you must abbreviate, do not use **GFM**. Use **GLFM** instead.

## GitLab Helm chart, GitLab chart

To deploy a cloud-native version of GitLab, use:

- The GitLab Helm chart (long version)
- The GitLab chart (short version)

Do not use **the `gitlab` chart**, **the GitLab Chart**, or **the cloud-native chart**.

You use the **GitLab Helm chart** to deploy **cloud-native GitLab** in a Kubernetes cluster.

If you use it in a context of describing the
[different installation methods](_index.md#how-to-document-different-installation-methods)
use `Helm chart (Kubernetes)`.

## GitLab Pages

For consistency and branding, use **GitLab Pages** rather than **Pages**.

However, if you use **GitLab Pages** for the first mention on a page or in the UI,
you can use **Pages** thereafter.

## GitLab Runner

Use title case for **GitLab Runner**. This is the product you install. For more information about the decision for this usage,
see [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/233529).

See also:

- [runners](#runner-runners)
- [runner managers](#runner-manager-runner-managers)
- [runner workers](#runner-worker-runner-workers)

## GitLab SaaS

**GitLab SaaS** refers to both [GitLab.com](#gitlabcom) (multi-tenant SaaS) as well as [GitLab Dedicated](#gitlab-dedicated) (single-tenant SaaS).

Try to avoid **GitLab SaaS** and instead, refer to the [specific offering](#offerings) instead.

## GitLab Self-Managed

Use **GitLab Self-Managed** to refer to an installation of GitLab that customers manage.

Use the descriptor of **instance** as needed. Do not use **installation**.

Use:

- GitLab Self-Managed
- a GitLab Self-Managed instance

Instead of:

- A GitLab Self-Managed installation
- A Self-Managed GitLab installation
- A self-managed GitLab installation
- A GitLab instance that is GitLab Self-Managed

You can use **instance** on its own to describe GitLab Self-Managed. For example:

- On your instance, ensure the port is open.
- Verify that the instance is publicly accessible.

See also [self-managed](#self-managed).

## GitLab.com

Use **GitLab.com** to refer to the URL or product offering. GitLab.com is the instance that's managed by GitLab.

## GitLab Workflow extension for VS Code

Use **GitLab Workflow extension for VS Code** to refer to the extension.
You can also use **GitLab Workflow for VS Code** or **GitLab Workflow**.

For terms in VS Code, see [VS Code user interface](#vs-code-user-interface)

## GraphiQL

Use **GraphiQL** or **GraphQL explorer** to refer to this tool.

In most cases, you should use **GraphiQL** on its own with no descriptor.

Do not use:

- GraphiQL explorer tool
- GraphiQL explorer

## group access token

Use sentence case for **group access token**.

Capitalize the first word when you refer to the UI.

## guide

We want to speak directly to users. On `docs.gitlab.com`, do not use **guide** as part of a page title.
For example, **Snowplow Guide**. Instead, speak about the feature itself, and how to use it. For example, **Use Snowplow to do xyz**.

## Guest

When writing about the Guest role:

- Use a capital **G**.
- Write it out:
  - Use: if you are assigned the Guest role
  - Instead of: if you are a guest

- When the Guest role is the minimum required role:
  - Use: at least the Guest role
  - Instead of: the Guest role or higher

Do not use bold.

Do not use **Guest permissions**. A user who is assigned the Guest role has a set of associated permissions.

## handy

Do not use **handy**. If the user doesn't find the feature or process to be handy, we lose their trust. ([Vale](../testing/vale.md) rule: [`Simplicity.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab_base/Simplicity.yml))

## high availability, HA

Do not use **high availability** or **HA**, except in the GitLab [reference architectures](../../../administration/reference_architectures/_index.md#high-availability-ha). Instead, direct readers to the reference architectures for more information about configuring GitLab for handling greater amounts of users.

Do not use phrases like **high availability setup** to mean a multiple node environment. Instead, use **multi-node setup** or similar.

## higher

Do not use **higher** when talking about version numbers.

Use:

- In GitLab 14.4 and later...

Instead of:

- In GitLab 14.4 and higher...
- In GitLab 14.4 and above...

## hit

Don't use **hit** to mean **press**.

Use:

- Press **ENTER**.

Instead of:

- Hit the **ENTER** button.

## I

Do not use first-person singular. Use **you** or rewrite the phrase instead.

## i.e.

Do not use Latin abbreviations. Use **that is** instead. ([Vale](../testing/vale.md) rule: [`LatinTerms.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab_base/LatinTerms.yml))

## in order to

Do not use **in order to**. Use **to** instead. ([Vale](../testing/vale.md) rule: [`Wordy.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab_base/Wordy.yml))

## indexes, indices

For the plural of **index**, use **indexes**.

However, for Elasticsearch, use [**indices**](https://www.elastic.co/blog/what-is-an-elasticsearch-index).

## Installation from source

When referring to the installation method using the self-compiled code, refer to it
as **self-compiled**.

Use:

- For self-compiled installations...

Instead of:

- For installations from source...

For more information, see the
[different installation methods](_index.md#how-to-document-different-installation-methods).

## -ing words

Remove **-ing** words whenever possible. They can be difficult to translate,
and more precise terms are usually available. For example:

- Instead of **The files using storage are deleted**, use **The files that use storage are deleted**.
- Instead of **Delete files using the Edit button**, use **Use the Edit button to delete files**.
- Instead of **Replicating your server is required**, use **You must replicate your server**.

## issue

Use lowercase for **issue**.

## issue board

Use lowercase for **issue board**.

## Issue Description Generation

Use title case for **Issue Description Generation**.

On first mention on a page, use **GitLab Duo Issue Description Generation**.
Thereafter, use **Issue Description Generation** by itself.

## Issue Discussion Summary

Use title case for **Issue Discussion Summary**.

On first mention on a page, use **GitLab Duo Issue Discussion Summary**.
Thereafter, use **Issue Discussion Summary** by itself.

## issue weights

Use lowercase for **issue weights**.

## IP address

Use **IP address** when refering to addresses used with Internet Protocal (IP). Do not refer to an IP address as an
**IP**.

## it

When you use the word **it**, ensure the word it refers to is obvious.
If it's not obvious, repeat the word rather than using **it**.

Use:

- The field returns a connection. The field accepts four arguments.

Instead of:

- The field returns a connection. It accepts four arguments.

See also [this, these, that, those](#this-these-that-those).

## job

Do not use **build** to be synonymous with **job**. A job is defined in the `.gitlab-ci.yml` file and runs as part of a pipeline.

If you want to use **CI** with the word **job**, use **CI/CD job** rather than **CI job**.

## Kubernetes executor

GitLab Runner can run jobs on a Kubernetes cluster. To do this, GitLab Runner uses the Kubernetes executor.

When referring to this feature, use:

- Kubernetes executor for GitLab Runner
- Kubernetes executor

Do not use:

- GitLab Runner Kubernetes executor, because this can infringe on the Kubernetes trademark.

## language model, large language model

When referring to language models, be precise. Not all language models are large,
and not all models are language models. When in doubt, ask a developer or PM for confirmation.

You can use LLM to refer to a large language model if you spell it out on first use.

## later

Use **later** when talking about version numbers.

Use:

- In GitLab 14.1 and later...

Instead of:

- In GitLab 14.1 and higher...
- In GitLab 14.1 and above...
- In GitLab 14.1 and newer...

## level

If you can, avoid using `level` in the context of an instance, project, or group.

Use:

- This setting is turned on for the instance.
- This setting is turned on for the group and its subgroups.
- This setting is turned on for projects.

Instead of:

- This setting is turned on at the instance level.
- This setting is turned on at the group level.
- This is a project-level setting.

## lifecycle, life cycle, life-cycle

Use one word for **lifecycle**. Do not use **life cycle** or **life-cycle**.

([Vale](../testing/vale.md) rule: [`SubstitutionWarning.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab_base/SubstitutionWarning.yml))

## list

Do not use **list** when referring to a [**dropdown list**](#dropdown-list).
Use the full phrase **dropdown list** instead.

Also, do not use **list** when referring to a page. For example, the **Issues** page
is populated with a list of issues. However, you should call it the **Issues** page,
and not the **Issues** list.

## license

Licenses are different than subscriptions.

- A license grants users access to the subscription they purchased. The license includes information like the number of seats and subscription dates.
- A subscription is the subscription tier that the user purchases.

Do not use the term [**cloud license**](#cloud-licensing).

The following terms are displayed in the UI and in emails. You can use them when necessary:

- **Online license** - a license synchronized with GitLab
- **Offline license** - a license not synchronized with GitLab
- **Legacy license** - a license created before synchronization was possible

However, if you can, rather than using the term, use the more specific description instead.

Use:

- Add a license to your instance.
- Purchase a subscription.

Instead of:

- Buy a license.
- Purchase a license.

## limitations

Do not use **limitations**. Use **known issues** instead.

## log in, log on

Do not use:

- **log in**.
- **log on**.
- **login**

Use [sign in](#sign-in-sign-in) instead.

However, if the user interface has **Log in**, you should match the UI.

## limited availability

Use lowercase for **limited availability**. For example:

- This feature has limited availability.
- Hosted runners are in limited availability.

Do not use:

- This feature has reached limited availability.

Do not use **LA** to abbreviate limited availability.

## logged-in user, logged in user

Use **authenticated user** instead of **logged-in user** or **logged in user**.

## lower

Do not use **lower** when talking about version numbers.

Use:

- In GitLab 14.1 and earlier.

Instead of:

- In GitLab 14.1 and lower.
- In GitLab 14.1 and older.

## machine learning

Use lowercase for **machine learning**.

When machine learning is used as an adjective, like **a machine learning model**,
do not hyphenate. While a hyphen might be more grammatically correct, we risk
becoming inconsistent if we try to be more precise.

## Maintainer

When writing about the Maintainer role:

- Use a capital **M**.
- Write it out.
  - Use: if you are assigned the Maintainer role
  - Instead of: if you are a maintainer

- When the Maintainer role is the minimum required role:
  - Use: at least the Maintainer role
  - Instead of: the Maintainer role or higher

Do not use bold.

Do not use **Maintainer permissions**. A user who is assigned the Maintainer role has a set of associated permissions.

## mankind

Do not use **mankind**. Use **people** or **humanity** instead. ([Vale](../testing/vale.md) rule: [`InclusiveLanguage.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab_base/InclusiveLanguage.yml))

## manpower

Do not use **manpower**. Use words like **workforce** or **GitLab team members**. ([Vale](../testing/vale.md) rule: [`InclusiveLanguage.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab_base/InclusiveLanguage.yml))

## master

Do not use **master**. Use **main** when you need a sample [default branch name](#branch).
([Vale](../testing/vale.md) rule: [`InclusiveLanguage.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab_base/InclusiveLanguage.yml))

## may, might

**Might** means something has the probability of occurring. Might is often used in troubleshooting documentation.

**May** gives permission to do something. Consider **can** instead of **may**.

Consider rewording phrases that use these terms. These terms often indicate possibility and doubt, and technical writing strives to be precise.

See also [you can](#you-can).

Use:

- The `committed_date` and `authored_date` fields are generated from different sources, and might not be identical.
- A typical pipeline consists of four stages, executed in the following order:

Instead of:

- The `committed_date` and `authored_date` fields are generated from different sources, and may not be identical.
- A typical pipeline might consist of four stages, executed in the following order:

## MB, megabytes

For **MB** and **GB**, follow the [Microsoft guidance](https://learn.microsoft.com/en-us/style-guide/a-z-word-list-term-collections/term-collections/bits-bytes-terms).

## member

When you add a [user account](#user-account) to a group or project,
the user account becomes a **member**.

## Merge Commit Message Generation

Use title case for **Merge Commit Message Generation**.

On first mention on a page, use **GitLab Duo Merge Commit Message Generation**.
Thereafter, use **Merge Commit Message Generation** by itself.

## merge request branch

Do not use **merge request branch**. See [branch](#branch).

## merge requests

Use lowercase for **merge requests**. If you use **MR** as the acronym, spell it out on first use.

## Merge Request Summary

Use title case for **Merge Request Summary**.

On first mention on a page, use **GitLab Duo Merge Request Summary**.
Thereafter, use **Merge Request Summary** by itself.

## milestones

Use lowercase for **milestones**.

## Minimal Access

When writing about the Minimal Access role:

- Use a capital **M** and a capital **A**.
- Write it out:
  - Use: if you are assigned the Minimal Access role
  - Instead of: if you are a Minimal Access user

- When the Minimal Access role is the minimum required role:
  - Use: at least the Minimal Access role
  - Instead of: the Minimal Access role or higher

Do not use bold.

Do not use **Minimal Access permissions**. A user who is assigned the Minimal Access role has a set of associated permissions.

## model registry

When documenting the GitLab model registry features and functionality, use lowercase.

Use:

- The GitLab model registry supports A, B, and C.
- You can publish a model to your project's model registry.

## models

For usage, see [language models](#language-model-large-language-model).

## n/a, N/A, not applicable

When possible, use **not applicable**. Spelling out the phrase helps non-English speaking users and avoids
capitalization inconsistencies.

## navigate

Do not use **navigate**. Use **go** instead. For example:

- Go to this webpage.
- Open a terminal and go to the `runner` directory.

([Vale](../testing/vale.md) rule: [`SubstitutionWarning.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab_base/SubstitutionWarning.yml))

## need to

Try to avoid **need to**, because it's wordy.

For example, when a variable is **required**,
instead of **You need to set the variable**, use:

- Set the variable.
- You must set the variable.

When the variable is **recommended**:

- You should set the variable.

When the variable is **optional**:

- You can set the variable.

## new

Often, you can avoid the word **new**. When you create an object, it is new,
so you don't need this additional word.

See also [**create**](#create) and [**add**](#add).

## newer

Do not use **newer** when talking about version numbers.

Use:

- In GitLab 14.4 and later...

Instead of:

- In GitLab 14.4 and higher...
- In GitLab 14.4 and above...
- In GitLab 14.4 and newer...

## normal, normally

Don't use **normal** to mean the usual, typical, or standard way of doing something.
Use those terms instead.

Use:

- Typically, you specify a certificate.
- Usually, you specify a certificate.
- Follow the standard Git workflow.

Instead of:

- Normally, you specify a certificate.
- Follow the normal Git workflow.

([Vale](../testing/vale.md) rule: [`Normal.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab_base/Normal.yml))

## note that

Do not use **note that** because it's wordy.

Use:

- You can change the settings.

Instead of:

- Note that you can change the settings.

## offerings

The current product offerings are:

- [GitLab.com](#gitlabcom)
- [GitLab Self-Managed](#self-managed)
- [GitLab Dedicated](#gitlab-dedicated)

The [availability details](availability_details.md) reflect these offerings.

## older

Do not use **older** when talking about version numbers.

Use:

- In GitLab 14.1 and earlier.

Instead of:

- In GitLab 14.1 and lower.
- In GitLab 14.1 and older.

## Omnibus GitLab

When referring to the installation method that uses the Linux package, refer to it
as **Linux package**.

Use:

- For installations that use the Linux package...

Instead of:

- For installations that use Omnibus GitLab...

For more information, see the
[different installation methods](_index.md#how-to-document-different-installation-methods).

## on

When documenting high-level UI elements, use **on** as a preposition. For example:

- On the left sidebar, select **Settings > CI/CD**.
- On the **Grant permission** dialog, select **Group**.

Do not use **from** or **in**. For more information, see the [Microsoft Style Guide](https://learn.microsoft.com/en-us/style-guide/a-z-word-list-term-collections/f/from-vs-on).

## once

The word **once** means **one time**. Don't use it to mean **after** or **when**.

Use:

- When the process is complete...

Instead of:

- Once the process is complete...

## only

Put the word **only** next to the word it modifies.

In the following example, **only** modifies the noun **projects**.
The meaning is that you can create one type of project--a private project.

- You can create only private projects.

In the following example, **only** modifies the verb **create**.
The meaning is that you can't perform other actions,
like deleting private projects, or adding users to them.

- You can only create private projects.

## override

Use **override** to indicate temporary replacement.

For example, a value might be overridden when a job runs. The
original value does not change.

## overwrite

Use **overwrite** to indicate permanent replacement.

For example, a log file might overwrite a log file of the same name.

## Owner

When writing about the Owner role:

- Use a capital **O**.
- Write it out.
  - Use: if you are assigned the Owner role
  - Instead of: if you are an owner

Do not use bold.

Do not use **Owner permissions**. A user who is assigned the Owner role has a set of associated permissions.
An Owner is the highest role a user can have.

## package registry

When documenting the GitLab package registry features and functionality, use lowercase.

Use:

- The GitLab package registry supports A, B, and C.
- You can publish a package to your project's package registry.

## page

If you write a phrase like, "On the **Issues** page," ensure steps for how to get to the page are nearby. Otherwise, people might not know what the **Issues** page is.

The page name should be visible in the UI at the top of the page,
or included in the breadcrumb.

The docs should match the case in the UI, and the page name should be bold. For example:

- On the **Test cases** page, ...

## parent

Always use as a compound noun.

Do not use **direct [ancestor](#ancestor)** or **ascendant**.

Examples:

- parent directory
- parent group
- parent project
- parent commit
- parent issue
- parent item
- parent epic
- parent objective
- parent pipeline

See also: [child](#child), and [subgroup](#subgroup).

## per

Do not use **per** because it can have several different meanings.

Use the specific prepositional phrase instead:

- for each
- through
- by
- every
- according to

## permissions

Do not use [**roles**](#roles) and **permissions** interchangeably. Each user is assigned a role. Each role includes a set of permissions.

Permissions are not the same as [**access levels**](#access-level).

## personal access token

Use sentence case for **personal access token**.

Capitalize the first word when you refer to the UI.

## Planner

When writing about the Planner role:

- Use a capital **P**.
- Write it out.
  - Use: if you are assigned the Planner role
  - Instead of: if you are a Planner

- When the Planner role is the minimum required role:
  - Use: at least the Planner role
  - Instead of: the Planner role or higher

Do not use bold.

Do not use **Planner permissions**. A user who is assigned the Planner role has a set of associated permissions.

## please

Do not use **please** in the product documentation.

In UI text, use **please** when we've inconvenienced the user. For more information,
see the [Microsoft Style Guide](https://learn.microsoft.com/en-us/style-guide/a-z-word-list-term-collections/p/please).

## Premium

Use **Premium**, in uppercase, for the subscription tier. When you refer to **Premium**
in the context of other subscription tiers, follow [the subscription tier](#subscription-tier) guidance.

## preferences

Use **preferences** to describe user-specific, system-level settings like theme and layout.

## prerequisites

Use **prerequisites** when documenting the tasks that must be completed or the conditions that must be met before a user can complete a task. Do not use **requirements**.

**Prerequisites** must always be plural, even if the list includes only one item.

For more information, see [the task topic type](../topic_types/task.md).

For tutorial page types, use [**before you begin**](#before-you-begin) instead.

## press

Use **press** when talking about keyboard keys. For example:

- To stop the command, press <kbd>Control</kbd>+<kbd>C</kbd>.

## profanity

Do not use profanity. Doing so may negatively affect other users and contributors, which is contrary to the GitLab value of [Diversity, Inclusion, and Belonging](https://handbook.gitlab.com/handbook/values/#diversity-inclusion).

## project

See [repository, project](#repository-project).

## project access token

Use sentence case for **project access token**.

Capitalize the first word when you refer to the UI.

## provision

Use the term **provision** when referring to provisioning cloud infrastructure. You provision the infrastructure, and then deploy applications to it.

For example, you might write something like:

- Provision an AWS EKS cluster and deploy your application to it.

## push rules

Use lowercase for **push rules**.

## quite

Do not use **quite** because it's wordy.

## `README` file

Use backticks and lowercase for **the `README` file**, or **the `README.md` file**.

When possible, use the full phrase: **the `README` file**

For plural, use **`README` files**.

## recommend, we recommend

Instead of **we recommend**, use **you should**. We want to talk to the user the way
we would talk to a colleague, and to avoid differentiation between `we` and `them`.

- You should set the variable. (It's recommended.)
- Set the variable. (It's required.)
- You can set the variable. (It's optional.)

See also [recommended steps](_index.md#recommended-steps).

## register

Use **register** instead of **sign up** when talking about creating an account.

## remove

Use **remove** when an object continues to exist. For example, you can remove an issue from an epic, but the issue still exists.

When an object is completely deleted, use [**delete**](#delete) instead.

## Reporter

When writing about the Reporter role:

- Use a capital **R**.
- Write it out.
  - Use: if you are assigned the Reporter role
  - Instead of: if you are a reporter

- When the Reporter role is the minimum required role:
  - Use: at least the Reporter role
  - Instead of: the Reporter role or higher

Do not use bold.

Do not use **Reporter permissions**. A user who is assigned the Reporter role has a set of associated permissions.

## repository, project

A GitLab project contains, among other things, a Git repository. Use **repository** when referring to the
Git repository. Use **project** to refer to the GitLab user interface for managing and configuring the
Git repository, wiki, and other features.

## Repository Mirroring

Use title case for **Repository Mirroring**.

## resolution, resolve

Use **resolution** when the troubleshooting solution fixes the issue permanently.
A resolution usually involves file and code changes to correct the problem.
For example:

- To resolve this issue, edit the `.gitlab-ci.yml` file.
- One resolution is to edit the `.gitlab-ci.yml` file.

See also [workaround](#workaround).

## requirements

When documenting the tasks that must be completed or the conditions that must be met before a user can complete the steps:

- Use **prerequisites** for tasks. For more information, see [the task topic type](../topic_types/task.md).
- Use **before you begin** for tutorials. For more information, see [the tutorial page type](../topic_types/tutorial.md).

Do not use **requirements**.

## reset

Use **reset** to describe the action associated with resetting an item to a new state.

## respectively

Avoid **respectively** and be more precise instead.

Use:

- To create a user, select **Create user**. For an existing user, select **Save changes**.

Instead of:

- Select **Create user** or **Save changes** if you created a new user or
  edited an existing one respectively.

## restore

See the [Microsoft Style Guide](https://learn.microsoft.com/en-us/style-guide/a-z-word-list-term-collections/r/restore) for guidance on **restore**.

## review app

Use lowercase for **review app**.

## roles

A user has a role **for** a project or group.

Use:

- You must have the Owner role for the group.

Instead of:

- You must have the Owner role of the group.

Do not use **roles** and [**permissions**](#permissions) interchangeably. Each user is assigned a role. Each role includes a set of permissions.

There are two types of roles: [custom](#custom-role) and [default](#default-role).

Roles are not the same as [**access levels**](#access-level).

## Root Cause Analysis

Use title case for **Root Cause Analysis**.

On first mention on a page, use **GitLab Duo Root Cause Analysis**.
Thereafter, use **Root Cause Analysis** by itself.

## roll back

Use **roll back** for changing a GitLab version to an earlier one.

Do not use **roll back** for licensing or subscriptions. Use **change the subscription tier** instead.

## runner, runners

Use lowercase for **runners**. These are the agents that run CI/CD jobs. See also [GitLab Runner](#gitlab-runner) and [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/233529).

When referring to runners, if you have to specify that the runners are installed on a customer's GitLab instance,
use **self-managed** rather than **self-hosted**.

When referring to the scope of runners, use:

- **project runner**: Associated with specific projects.
- **group runner**: Available to all projects and subgroups in a group.
- **instance runner**: Available to all groups and projects in a GitLab instance.

## runner manager, runner managers

Use lowercase for **runner managers**. These are a type of runner that can create multiple runners for autoscaling. See also [GitLab Runner](#gitlab-runner).

## runner worker, runner workers

Use lowercase for **runner workers**. This is the process created by the runner on the host computing platform to run jobs. See also [GitLab Runner](#gitlab-runner).

## runner authentication token

Use **runner authentication token** instead of variations like **runner token**, **authentication token**, or **token**.
Runners are assigned runner authentication tokens when they are created, and use them to authenticate with GitLab when
they execute jobs.

## Runner SaaS, SaaS runners

Do not use **Runner SaaS** or **SaaS runners**.

Use **GitLab-hosted runners** as the main feature name that describes runners hosted on GitLab.com and GitLab Dedicated.

To specify offerings and operating systems use:

- **hosted runners for GitLab.com**
- **hosted runners for GitLab Dedicated**
- **hosted runners on Linux for GitLab.com**
- **hosted runners on Windows for GitLab.com**

Do not use **hosted runners** without the **GitLab-** prefix or without the offering or operating system.

## (s)

Do not use **(s)** to make a word optionally plural. It can slow down comprehension. For example:

Use:

- Select the jobs you want.

Instead of:

- Select the job(s) you want.

If you can select multiples of something, then write the word as plural.

## sanity check

Do not use **sanity check**. Use **check for completeness** instead. ([Vale](../testing/vale.md) rule: [`InclusiveLanguage.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab_base/InclusiveLanguage.yml))

## scalability

Do not use **scalability** when talking about increasing GitLab performance for additional users. The words scale or scaling
are sometimes acceptable, but references to increasing GitLab performance for additional users should direct readers
to the GitLab [reference architectures](../../../administration/reference_architectures/_index.md) page.

## search

When you search, you type a string in the search box on the left sidebar.
The search results are displayed on a search page.

Searching is different from [filtering](#filter).

## seats

When referring to the subscription billing model:

- For GitLab.com, use **seats**. Customers purchase seats. Users occupy seats when they are invited
  to a group, with some [exceptions](../../../subscriptions/gitlab_com/_index.md#how-seat-usage-is-determined).
- For GitLab Self-Managed, use **users**. Customers purchase subscriptions for a specified number of **users**.

## section

Use **section** to describe an area on a page. For example, if a page has lines that separate the UI
into separate areas, refer to these areas as sections.

We often think of expandable/collapsible areas as **sections**. When you refer to expanding
or collapsing a section, don't include the word **section**.

Use:

- Expand **Auto DevOps**.

Instead of:

- Do not: Expand the **Auto DevOps** section.

## select

Use **select** with buttons, links, menu items, and lists. **Select** applies to more devices,
while **click** is more specific to a mouse.

However, you can make an exception for **right-click** and **click-through demo**.

## self-hosted model

Use **self-hosted model** (lowercase) to refer to a language model that's hosted by a customer, rather than GitLab.

The language model might be an LLM (large language model), but it might not be.

## Self-Hosted

To avoid confusion with [**GitLab Self-Managed**](#gitlab-self-managed),
when referring to the [**GitLab Duo Self-Hosted** feature](#gitlab-duo-self-hosted),
do not use **Self-Hosted** by itself.

Always write **GitLab Duo Self-Hosted** in full and in title case, unless you are
[referring to a language model that's hosted by a customer, rather than GitLab](#self-hosted-model).

## self-managed

Use **GitLab Self-Managed** to refer to a customer's installation of GitLab.

- Do not use **self-hosted**.

See [GitLab Self-Managed](#gitlab-self-managed).

## Service Desk

Use title case for **Service Desk**.

## setup, set up

Use **setup** as a noun, and **set up** as a verb. For example:

- Your remote office setup is amazing.
- To set up your remote office correctly, consider the ergonomics of your work area.

Do not confuse **set up** with [**configure**](#configure).
**Set up** implies that it's the first time you've done something. For example:

1. Set up your installation.
1. Configure your installation.

## settings

A **setting** changes the default behavior of the product. A **setting** consists of a key/value pair,
typically represented by a label with one or more options.

## sign in, sign-in

To describe the action of signing in, use:

- **sign in**.
- **sign in to** as a verb. For example: Use your password to sign in to GitLab.

You can also use:

- **sign-in** as a noun or adjective. For example: **sign-in page** or
  **sign-in restrictions**.
- **single sign-on**.

Do not use:

- **sign on**.
- **sign into**.
- [**log on**, **log in**, or **log into**](#log-in-log-on).

If the user interface has different words, you can use those.

## sign up

Use **register** instead of **sign up** when talking about creating an account.

## signed-in user, signed in user

Use **authenticated user** instead of **signed-in user** or **signed in user**.

## simply, simple

Do not use **simply** or **simple**. If the user doesn't find the process to be simple, we lose their trust. ([Vale](../testing/vale.md) rule: [`Simplicity.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab_base/Simplicity.yml))

## since

The word **since** indicates a timeframe. For example, **Since 1984, Bon Jovi has existed**. Don't use **since** to mean **because**.

Use:

- Because you have the Developer role, you can delete the widget.

Instead of:

- Since you have the Developer role, you can delete the widget.

## slashes

Instead of **and/or**, use **or** or re-write the sentence. This rule also applies to other slashes, like **follow/unfollow**. Some exceptions (like **CI/CD**) are allowed.

## slave

Do not use **slave**. Another option is **secondary**. ([Vale](../testing/vale.md) rule: [`InclusiveLanguage.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab_base/InclusiveLanguage.yml))

## storages

In the context of:

- Gitaly, storage is physical and must be called a **storage**.
- Gitaly Cluster, storage can be either:
  - Virtual and must be called a **virtual storage**.
  - Physical and must be called a **physical storage**.

Gitaly storages have physical paths and virtual storages have virtual paths.

## subgroup

Use **subgroup** (no hyphen) instead of **sub-group**.
Also, avoid using alternative terms for subgroups, such as **child group** or **low-level group**.

([Vale](../testing/vale.md) rule: [`SubstitutionWarning.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab_base/SubstitutionWarning.yml))

## subscription tier

Do not confuse **subscription** or **subscription tier** with **[license](#license)**.
A user purchases a **subscription**. That subscription has a **tier**.

To describe tiers:

| Instead of                      | Use                                    |
|---------------------------------|----------------------------------------|
| In the Free tier or greater     | In all tiers                           |
| In the Free tier or higher      | In all tiers                           |
| In the Premium tier or greater  | In the Premium and Ultimate tier       |
| In the Premium tier or higher   | In the Premium and Ultimate tier       |
| In the Premium tier or lower    | In the Free and Premium tier           |

## Suggested Reviewers

Use title case for **Suggested Reviewers**.

**Suggested Reviewers** should always be plural, and is capitalized even if it's generic.

Examples:

- Suggested Reviewers can recommend a person to review your merge request. (This phrase describes the feature.)
- As you type, Suggested Reviewers are displayed. (This phrase is generic but still uses capital letters.)

## tab

Use bold for tab names. For example:

- The **Pipelines** tab
- The **Overview** tab

## that

Do not use **that** when describing a noun. For example:

Use:

- The file you save...

Instead of:

- The file **that** you save...

See also [this, these, that, those](#this-these-that-those).

## terminal

Use lowercase for **terminal**. For example:

- Open a terminal.
- From a terminal, run the `docker login` command.

## Terraform Module Registry

Use title case for the GitLab Terraform Module Registry, but use lowercase `m` when
talking about non-specific modules. For example:

- You can publish a Terraform module to your project's Terraform Module Registry.

## Test Generation

Use title case for **Test Generation**.

On first mention on a page, use **GitLab Duo Test Generation**.
Thereafter, use **Test Generation** by itself.

## text box

Use **text box** instead of **field** or **box** when referring to the UI element.

## there is, there are

Try to avoid **there is** and **there are**. These phrases hide the subject.

Use:

- The bucket has holes.

Instead of:

- There are holes in the bucket.

## they

Avoid the use of gender-specific pronouns, unless referring to a specific person.
Use a singular [they](https://developers.google.com/style/pronouns#gender-neutral-pronouns) as
a gender-neutral pronoun.

## this, these, that, those

Always follow these words with a noun. For example:

- Use: **This setting** improves performance.
- Instead of: **This** improves performance.

- Use: **These pants** are the best.
- Instead of: **These** are the best.

- Use: **That droid** is the one you are looking for.
- Instead of: **That** is the one you are looking for.

- Use: **Those settings** need to be configured. (Or even better, **Configure those settings.**)
- Instead of: **Those** need to be configured.

## to which, of which

Try to avoid **to which** and **of which**, and let the preposition dangle at the end of the sentence instead.
For examples, see [Prepositions](_index.md#prepositions).

## to-do item

Use lowercase and hyphenate **to-do** item. ([Vale](../testing/vale.md) rule: [`ToDo.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab_base/ToDo.yml))

## To-Do List

Use title case for **To-Do List**. ([Vale](../testing/vale.md) rule: [`ToDo.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab_base/ToDo.yml))

## toggle

You **turn on** or **turn off** a toggle. For example:

- Turn on the **blah** toggle.

## top-level group

Use lowercase for **top-level group** (hyphenated).

Do not use **root group**.

## TFA, two-factor authentication

Use [**2FA** and **two-factor authentication**](#2fa-two-factor-authentication) instead.

## turn on, turn off

Use **turn on** and **turn off** instead of **enable** or **disable**.

For details, see [the Microsoft style guide](https://learn.microsoft.com/en-us/style-guide/a-z-word-list-term-collections/t/turn-on-turn-off).

See also [enable](#enable) and [disable](#disable).

## type

Use **type** when the cursor remains where you're typing. For example,
in a search box, you begin typing and search results appear. You do not
click out of the search box.

For example:

- To view all users named Alex, type `Al`.
- To view all labels for the documentation team, type `doc`.
- For a list of quick actions, type `/`.

See also [**enter**](#enter).

## Ultimate

Use **Ultimate**, in uppercase, for the subscription tier. When you refer to **Ultimate**
in the context of other subscription tiers, follow [the subscription tier](#subscription-tier) guidance.

## undo

See the [Microsoft Style Guide](https://learn.microsoft.com/en-us/style-guide/a-z-word-list-term-collections/u/undo) for guidance on **undo**.

## units of measurement

Use a space between the number and the unit of measurement. For example, **128 GB**.
([Vale](../testing/vale.md) rule: [`Units.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab_base/Units.yml))

For more information, see the
[Microsoft Style Guide](https://learn.microsoft.com/en-us/style-guide/a-z-word-list-term-collections/term-collections/bits-bytes-terms).

## update

Use **update** for installing a newer **patch** version of the software only. For example:

- Update GitLab from 14.9 to 14.9.1.

Do not use **update** for any other case. Instead, use **[upgrade](#upgrade)** or **[edit](#edit)**.

## upgrade

Use **upgrade** for:

- Choosing a higher subscription tier (Premium or Ultimate).
- Installing a newer **major** (13.0) or **minor** (13.2) version of GitLab.

For example:

- Upgrade to GitLab Ultimate.
- Upgrade GitLab from 14.0 to 14.1.
- Upgrade GitLab from 14.0 to 15.0.

Use caution with the phrase **Upgrade GitLab** without any other text.
Ensure the surrounding text clarifies whether
you're talking about the product version or the subscription tier.

See also [downgrade](#downgrade) and [roll back](#roll-back).

## upper left, upper right

Use **upper-left corner** and **upper-right corner** to provide direction in the UI.
If the UI element is not in a corner, use **upper left** and **upper right**.

Do not use **top left** and **top right**.

For more information, see the [Microsoft Style Guide](https://learn.microsoft.com/en-us/style-guide/a-z-word-list-term-collections/u/upper-left-upper-right).

## useful

Do not use **useful**. If the user doesn't find the process to be useful, we lose their trust. ([Vale](../testing/vale.md) rule: [`Simplicity.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab_base/Simplicity.yml))

## user account

You create a **user account**. The user account has an [access level](#access-level).
When you add a **user account** to a group or project, the user account becomes a **member**.

## using

Avoid **using** in most cases. It hides the subject and makes the phrase more difficult to translate.
Use **by using**, **that use**, or re-write the sentence.

For example:

- Instead of: The files using storage...
- Use: The files that use storage...

- Instead of: Change directories using the command line.
- Use: Change directories by using the command line. Or even better: To change directories, use the command line.

## utilize

Do not use **utilize**. Use **use** instead. It's more succinct and easier for non-native English speakers to understand.
([Vale](../testing/vale.md) rule: [`SubstitutionWarning.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab_base/SubstitutionWarning.yml))

## version, v

To describe versions of GitLab, use **GitLab `<version number>`**. For example:

- You must have GitLab 16.0 or later.

To describe other software, use the same style as the documentation for that software.
For example:

- In Kubernetes 1.4, you can...

Pay attention to spacing by the letter **v**. In semantic versioning, no space exists after the **v**. For example:

- v1.2.3

## via

Do not use Latin abbreviations. Use **with**, **through**, or **by using** instead. ([Vale](../testing/vale.md) rule: [`LatinTerms.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab_base/LatinTerms.yml))

## VS Code user interface

When describing the user interface of VS Code and the Web IDE, follow the usage and capitalization of the
[VS Code documentation](https://code.visualstudio.com/docs/getstarted/userinterface), such as Command Palette
and Primary Side Bar.

## Vulnerability Explanation

Use title case for **Vulnerability Explanation**.

On first mention on a page, use **GitLab Duo Vulnerability Explanation**.
Thereafter, use **Vulnerability Explanation** by itself.

## Vulnerability Resolution

Use title case for **Vulnerability Resolution**.

On first mention on a page, use **GitLab Duo Vulnerability Resolution**.
Thereafter, use **Vulnerability Resolution** by itself.

## we

Try to avoid **we** and focus instead on how the user can accomplish something in GitLab.

Use:

- Use widgets when you have work you want to organize.

Instead of:

- We created a feature for you to add widgets.

## Web IDE user interface

See [VS Code user interface](#vs-code-user-interface).

## workaround

Use **workaround** when the troubleshooting solution is a temporary fix.
A workaround is usually an immediate fix and might have ongoing issues.
For example:

- The workaround is to temporarily pin your template to the deprecated version.

See also [resolution](#resolution-resolve).

## while

Use **while** to refer only to something occurring in time. For example,
**Leave the window open while the process runs.**

Do not use **while** for comparison. For example, use:

- Job 1 can run quickly. However, job 2 is more precise.

Instead of:

- While job 1 can run quickly, job 2 is more precise.

For more information, see the [Microsoft Style Guide](https://learn.microsoft.com/en-us/style-guide/a-z-word-list-term-collections/w/while).

## whilst

Do not use **whilst**. Use [while](#while) instead. **While** is more succinct and easier for non-native English speakers to understand.

## whitelist

Do not use **whitelist**. Another option is **allowlist**. ([Vale](../testing/vale.md) rule: [`InclusiveLanguage.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab_base/InclusiveLanguage.yml))

## within

When possible, do not use **within**. Use **in** instead, unless you are referring to a time frame, limit, or boundary. For example:

- The upgrade occurs within the four-hour maintenance window.
- The Wi-Fi signal is accessible within a 30-foot radius.

([Vale](../testing/vale.md) rule: [`SubstitutionWarning.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab_base/SubstitutionWarning.yml))

## yet

Do not use **yet** when talking about the product or its features. The documentation describes the product as it is today.

Sometimes you might need to use **yet** when writing a task. If you use
**yet**, ensure the surrounding phrases are written
in present tense, active voice.

[View guidance about how to write about future features](_index.md#promising-features-in-future-versions).

## you, your, yours

Use **you** instead of **the user**, **the administrator** or **the customer**.
Documentation should speak directly to the user, whether that user is someone installing the product,
configuring it, administering it, or using it.

Use:

- You can configure a pipeline.
- You can reset a user's password. (In content for an administrator)

Instead of:

- Users can configure a pipeline.
- Administrators can reset a user's password.

## you can

When possible, start sentences with an active verb instead of **you can**.
For example:

- Use code review analytics to view merge request data.
- Create a board to organize your team tasks.
- Configure variables to restrict pushes to a repository.
- Add links to external accounts you have, like Skype and Twitter.

Use **you can** for optional actions. For example:

- Use code review analytics to view metrics per merge request. You can also use the API.
- Enter the name and value pairs. You can add up to 20 pairs per streaming destination.

<!-- vale on -->
<!-- markdownlint-enable -->
