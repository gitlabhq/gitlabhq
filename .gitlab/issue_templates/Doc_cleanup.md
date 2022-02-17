<!--
* Use this issue template for identifying issues to work on in existing documentation, normally identified
* with our [Vale](https://docs.gitlab.com/ee/development/documentation/testing.html#vale) or [markdownlint](https://docs.gitlab.com/ee/development/documentation/testing.html#markdownlint) tools. Much of this identified work is suitable for first-time contributors or
* for work during Hackathons.
*
* Normal documentation updates should use the Documentation template, and documentation work as part of
* feature development should use the Feature Request template.
-->

## Identified documentation issue

<!--
* Include information about the issue that needs resolution. If the item is from an automated test,
* be sure to include a copy/paste from the the test results. [This issue](https://gitlab.com/gitlab-org/gitlab/-/issues/339543) is an example of text to include with a Vale issue.
*
* Limit the identified work to be related to one another, and keep it to a reasonable amount. For example,
* several moderate changes on one page, a few intermediate changes across five pages, or several very small
* changes for up to 10 pages. Larger items should be broken out into other issues to better distribute
* the opportunities for contributors.
-->

## Process

If you, as a contributor, decide to take this work on, assign this issue to yourself, and create one or more linked
merge requests that resolve this issue. Be sure to close this issue after all linked merge requests are completed.

The work for this issue should involve only what's listed in the previous section. If you identify other work that
needs to be done, create separate, unlinked MRs as needed to address those items.

When using automated test results for identified work, use this issue to work only on the listed lines. For
example, if the tests list several lines that show the word "admin" as needing to possibly be "administrator,"
do not modify other parts of the page that may also include "admin," as the testing may have excluded those lines
(for example, they may be part of the **Admin Area** of GitLab).

## Additional information

<!--
* Any concepts, procedures, reference info we could add to make it easier to successfully use GitLab?
* Include use cases, benefits, and/or goals for this work.
* If adding content: What audience is it intended for? (What roles and scenarios?)
  For ideas, see personas at https://about.gitlab.com/handbook/marketing/product-marketing/roles-personas/ or the persona labels at
  https://gitlab.com/groups/gitlab-org/-/labels?subscribed=&search=persona%3A
-->

### Who can address the issue

<!-- What if any special expertise is required to resolve this issue? -->

### Other links/references

<!-- For example, related GitLab issues/MRs -->

/label ~documentation
