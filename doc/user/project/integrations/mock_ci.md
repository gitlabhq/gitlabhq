---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Mock CI **(FREE)**

NOTE:
This integration only appears if you're in a [development environment](https://gitlab.com/gitlab-org/gitlab-mock-ci-service#setup-mockci-integration).

To set up the mock CI service server, respond to the following endpoints:

- `commit_status`: `#{project.namespace.path}/#{project.path}/status/#{sha}.json`
  - Have your service return `200 { status: ['failed'|'canceled'|'running'|'pending'|'success'|'success-with-warnings'|'skipped'|'not_found'] }`.
  - If the service returns a 404, the service is interpreted as `pending`.
- `build_page`: `#{project.namespace.path}/#{project.path}/status/#{sha}`
  - Where the build is linked to (whether or not it's implemented).

For an example of a mock CI server, see [`gitlab-org/gitlab-mock-ci-service`](https://gitlab.com/gitlab-org/gitlab-mock-ci-service).
