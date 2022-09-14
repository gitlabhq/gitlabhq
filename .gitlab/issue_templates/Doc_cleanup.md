<!--
* Use this issue template for identifying issues to work on in existing documentation, normally identified
* with our [Vale](https://docs.gitlab.com/ee/development/documentation/testing.html#vale) or [markdownlint](https://docs.gitlab.com/ee/development/documentation/testing.html#markdownlint) tools. Much of this identified work is suitable for first-time contributors or
* for work during Hackathons.
*
* Normal documentation updates should use the Documentation template, and documentation work as part of
* feature development should use the Feature Request template.
-->

If you are a community contributor, **do not work on the issue if it is not assigned to you yet**.

Additionally, please review these points before working on this issue:

1. If you would like to work on the issue, type `@gl-docsteam I would like to work on this issue.`
   in a comment. A technical writer will assign the issue to you. If someone has already chosen this issue,
   pick another issue, or view docs [in the docs directory](https://gitlab.com/gitlab-org/gitlab/-/tree/master/doc)
   and open a merge request for any page you feel can be improved.
1. Carefully review the [merge request guidelines for contributors](https://docs.gitlab.com/ee/development/contributing/merge_request_workflow.html#merge-request-guidelines-for-contributors).
1. Carefully review the [commit message guidelines](https://docs.gitlab.com/ee/development/contributing/merge_request_workflow.html#commit-messages-guidelines).
1. Create a merge request for the issue:
   - If you were not assigned the issue, do not create a merge request. It will not be accepted.
   - If this is for a Hackathon, do not create the merge request before the Hackathon has started
     or it will not be counted towards the Hackathon.
   - Unless otherwise stated below, we expect one merge request per issue, so combine
     all changes together. If there is too much work for you to handle in one merge request,
     you can create more, but try to keep the number of merge requests as small as possible.
   - Select the **Documentation** merge request description template, and fill it out
     with the details of your work.
   - Copy the link to this issue and add it to the merge request's description,
     which links the merge request and the issue together.
1. After your merge request is accepted and merged, close this issue.

If you notice things you'd like to fix that are not part of the issue, open separate merge requests for those issues.

We're sorry for all the rules but we want everyone to have a good experience, and it can be hard when we get an influx of contributions.

Thank you again for contributing to the GitLab documentation!

## Identified documentation issue

<!--
* Include information about the issue that needs resolution. If the item is from an automated test,
* be sure to include a copy/paste from the the test results. [This issue](https://gitlab.com/gitlab-org/gitlab/-/issues/339543) is an example of text to include with a Vale issue.
*
* Limit the identified work to be related to one another, and keep it to a reasonable amount. For example,
* several moderate changes on one page, a few intermediate changes across five pages, or several very small
* changes for up to 10 pages. Larger items should be broken out into other issues to better distribute
* the opportunities for contributors.
*
* If you expect the work to take more than one MR to resolve, explain approximately
* how many MRs you expect to receive for the issue.
-->

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
