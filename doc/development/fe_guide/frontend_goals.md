---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Frontend Goals

This section defined the _desired state_ of the GitLab frontend how we see it over the next few years.

## Cluster SPAs

Currently, GitLab mostly follows Rails architecture and Rails routing which means every single time we're changing route, we have page reload. This results in long loading times because we are:

- rendering HAML page;
- mounting Vue applications if we have any;
- fetching data for these applications

Ideally, we should reduce the number of times user needs to go through this long process. This would be possible with converting GitLab into a single-page application but this would require significant refactoring and is not an achieavable short/mid-term goal.

The realistic goal is to move to _multiple SPAs_ experience where we define the _clusters_ of pages that form the user flow, and move this cluster from Rails routing to a single-page application with client-side routing. This way, we can load all the relevant context from HAML only once, and fetch all the additional data from the API depending on the route. An example of a cluster could be the following pages:

- issues list
- issue boards
- issue details page
- new issue
- editing an issue

All of them have the same context (project path, current user etc.), we could easily fetch more data with issue-specific parameter (issue `iid`) and store the results on the client (so that opening the same issue won't require more API calls). This leads to a smooth user experience for navigating through issues.

For navigation between clusters, we can still rely on Rails routing. These cases should be relatively more scarce than navigation within clusters.
