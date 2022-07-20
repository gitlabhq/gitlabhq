---
type: reference, howto
stage: Secure
group: Threat Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Generate test vulnerabilities

You can generate test vulnerabilities when you work on the [Vulnerability Report](../vulnerability_report/index.md).

1. Go to `/-/profile/personal_access_tokens` and generate a personal access token with `api` permissions.
1. Go to your project page and find the project ID. You can find the project ID below the project title.
1. Open a terminal and go to the `gitlab/qa` directory.
1. Run the following command:

```shell
GITLAB_QA_ACCESS_TOKEN=<your_personal_access_token> GITLAB_URL="http://localhost:3000" bundle exec rake vulnerabilities:setup\[<your_project_id>,<vulnerability_count>\] --trace
```

Make sure you do the following:

- Replace `<your_personal_access_token>` with the token you generated in step one.
- Double check the `GITLAB_URL`. It should point to the running local instance.
- Replace `<your_project_id>` with the ID you obtained in step two.
- Replace `<vulnerability_count>` with the number of vulnerabilities you'd like to generate.

The script creates the specified amount of vulnerabilities in the project.
