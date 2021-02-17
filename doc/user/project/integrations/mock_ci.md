---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Mock CI Service **(FREE)**

**NB: This service is only listed if you are in a development environment!**

To set up the mock CI service server, respond to the following endpoints

- `commit_status`: `#{project.namespace.path}/#{project.path}/status/#{sha}.json`
  - Have your service return `200 { status: ['failed'|'canceled'|'running'|'pending'|'success'|'success-with-warnings'|'skipped'|'not_found'] }`
  - If the service returns a 404, it is interpreted as `pending`
- `build_page`: `#{project.namespace.path}/#{project.path}/status/#{sha}`
  - Just where the build is linked to, doesn't matter if implemented

For an example of a mock CI server, see [`gitlab-org/gitlab-mock-ci-service`](https://gitlab.com/gitlab-org/gitlab-mock-ci-service)
