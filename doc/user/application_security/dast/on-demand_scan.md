---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: DAST on-demand scan
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

WARNING:
Do not run DAST scans against a production server. Not only can it perform *any* function that a user can, such
as clicking buttons or submitting forms, but it may also trigger bugs, leading to modification or loss of production data.
Only run DAST scans against a test server.

## On-demand scans

> - Runner tags selection [enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/111499) in GitLab 16.3.
> - Browser based on-demand DAST scans available in GitLab 17.0 and later because [proxy-based DAST was removed in the same version](../../../update/deprecations.md#proxy-based-dast-deprecated).

An on-demand DAST scan runs outside the DevOps lifecycle. Changes in your repository don't trigger
the scan. You must either start it manually, or schedule it to run. For on-demand DAST scans,
a [site profile](#site-profile) defines **what** is to be scanned, and a
[scanner profile](#scanner-profile) defines **how** the application is to be scanned.

An on-demand scan can be run in active or passive mode:

- **Passive mode**: The default mode, which runs a [Passive Browser based scan](browser/_index.md#passive-scans).
- **Active mode**: Runs an [Active Browser based scan](browser/_index.md#active-scans) which is potentially harmful to the site being scanned. To
  minimize the risk of accidental damage, running an active scan requires a
  [validated site profile](#site-profile-validation).

### View on-demand DAST scans

To view on-demand scans:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Secure > On-demand scans**.

On-demand scans are grouped by their status. The scan library contains all available on-demand
scans.

### Run an on-demand DAST scan

Prerequisites:

- You must have permission to run an on-demand DAST scan against a protected branch. The default
  branch is automatically protected. For more information, see
  [Pipeline security on protected branches](../../../ci/pipelines/_index.md#pipeline-security-on-protected-branches).

To run an existing on-demand scan:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure > On-demand scans**.
1. Select the **Scan library** tab.
1. In the scan's row, select **Run scan**.

   If the branch saved in the scan no longer exists, you must:

   1. [Edit the scan](#edit-an-on-demand-scan).
   1. Select a new branch.
   1. Save the edited scan.

The on-demand DAST scan runs, and the project's dashboard shows the results.

#### Create an on-demand scan

Create an on-demand scan to:

- Run it immediately.
- Save it to be run in the future.
- Schedule it to be run at a specified schedule.

To create an on-demand DAST scan:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Secure > On-demand scans**.
1. Select **New scan**.
1. Complete the **Scan name** and **Description** fields.
1. In the **Branch** dropdown list, select the desired branch.
1. Optional. Select the runner tags.
1. Select **Select scanner profile** or **Change scanner profile** to open the drawer, and either:
   - Select a scanner profile from the drawer, **or**
   - Select **New profile**, create a [scanner profile](#scanner-profile), then select **Save profile**.
1. Select **Select site profile** or **Change site profile** to open the drawer, and either:
   - Select a site profile from the **Site profile library** drawer, or
   - Select **New profile**, create a [site profile](#site-profile), then select **Save profile**.
1. To run the on-demand scan:

   - Immediately, select **Save and run scan**.
   - In the future, select **Save scan**.
   - On a schedule:

     - Turn on the **Enable scan schedule** toggle.
     - Complete the schedule fields.
     - Select **Save scan**.

The on-demand DAST scan runs as specified and the project's dashboard shows the results.

### View details of an on-demand scan

Prerequisites:

- You must be able to push to the branch associated with the DAST scan.

To view details of an on-demand scan:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure > On-demand scans**.
1. Select the **Scan library** tab.
1. In the saved scan's row select **More actions** (**{ellipsis_v}**), then select **Edit**.

### Edit an on-demand scan

Prerequisites:

- You must be able to push to the branch associated with the DAST scan.

To edit an on-demand scan:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure > On-demand scans**.
1. Select the **Scan library** tab.
1. In the saved scan's row select **More actions** (**{ellipsis_v}**), then select **Edit**.
1. Edit the saved scan's details.
1. Select **Save scan**.

### Delete an on-demand scan

Prerequisites:

- You must be able to push to the branch associated with the DAST scan.

To delete an on-demand scan:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure > On-demand scans**.
1. Select the **Scan library** tab.
1. In the saved scan's row select **More actions** (**{ellipsis_v}**), then select **Delete**.
1. On the confirmation dialog, select **Delete**.

## Site profile

> - Site profile features, scan method and file URL, were [enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/345837) in GitLab 15.6.
> - GraphQL endpoint path feature was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/378692) in GitLab 15.7.
> - Additional variables [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/177703) in GitLab 17.9.

A site profile defines the attributes and configuration details of the deployed application,
website, or API to be scanned by DAST.

A site profile contains:

- **Profile name**: A name you assign to the site to be scanned. While a site profile is referenced
  in either `.gitlab-ci.yml` or an on-demand scan, it **cannot** be renamed.
- **Site type**: The type of target to be scanned, either website or API scan.
- **Target URL**: The URL that DAST runs against.
- **Excluded URLs**: A comma-separated list of URLs to exclude from the scan.
- **Request headers**: A comma-separated list of HTTP request headers, including names and values. These headers are added to every request made by DAST.
- **Authentication**:
  - **Authenticated URL**: The URL of the page containing the sign-in HTML form on the target website. The username and password are submitted with the login form to create an authenticated scan.
  - **Username**: The username used to authenticate to the website.
  - **Password**: The password used to authenticate to the website.
  - **Username form field**: The name of username field at the sign-in HTML form.
  - **Password form field**: The name of password field at the sign-in HTML form.
  - **Submit form field**: The `id` or `name` of the element that when selected submits the sign-in HTML form.

- **Scan method**: A type of method to perform API testing. The supported methods are OpenAPI, Postman Collections, HTTP Archive (HAR), or GraphQL.
  - **GraphQL endpoint path**: The path to the GraphQL endpoint. This path is concatenated with the target URL to provide the URI for the scan to test. The GraphQL endpoint must support introspection queries.
  - **File URL**: The URL of the OpenAPI, Postman Collection, or HTTP Archive file.
- **Additional variables**: A list of environment variables to configure specific scan behaviors. These variables provide the same configuration options as pipeline-based DAST scans, such as setting timeouts, adding an authentication success URL, or enabling advanced scan features.

When an API site type is selected, a host override is used to ensure the API being scanned is on the same host as the target. This is done to reduce the risk of running an active scan against the wrong API.

When configured, request headers and password fields are encrypted using [`aes-256-gcm`](https://en.wikipedia.org/wiki/Advanced_Encryption_Standard) before being stored in the database.
This data can only be read and decrypted with a valid secrets file.

You can reference a site profile in `.gitlab-ci.yml` and
on-demand scans.

```yaml
stages:
  - dast

include:
  - template: DAST.gitlab-ci.yml

dast:
  stage: dast
  dast_configuration:
    site_profile: "<profile name>"
```

### Site profile validation

Site profile validation reduces the risk of running an active scan against the wrong website. A site
must be validated before an active scan can run against it. Each of the site validation methods are
equivalent in functionality, so use whichever is most suitable:

- **Text file validation**: Requires a text file be uploaded to the target site. The text file is
  allocated a name and content that is unique to the project. The validation process checks the
  file's content.
- **Header validation**: Requires the header `Gitlab-On-Demand-DAST` be added to the target site,
  with a value unique to the project. The validation process checks that the header is present, and
  checks its value.
- **Meta tag validation**: Requires the meta tag named `gitlab-dast-validation` be added to the
  target site, with a value unique to the project. Make sure it's added to the `<head>` section of
  the page. The validation process checks that the meta tag is present, and checks its value.

### Create a site profile

To create a site profile:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure > Security configuration**.
1. In the **Dynamic Application Security Testing (DAST)** section, select **Manage profiles**.
1. Select **New > Site profile**.
1. Complete the fields then select **Save profile**.

The site profile is saved, for use in an on-demand scan.

### Edit a site profile

Prerequisites:

- If a DAST scan uses the profile, you must be able to push to the branch associated with the scan.

NOTE:
If a site profile is linked to a security policy, you cannot edit the profile from this page. See
[Scan execution policies](../policies/scan_execution_policies.md) for more information.

NOTE:
If a site profile's Target URL or Authenticated URL is updated, the request headers and password fields associated with that profile are cleared.

When a validated site profile's file, header, or meta tag is edited, the site's
[validation status](#site-profile-validation) is revoked.

To edit a site profile:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure > Security configuration**.
1. In the **Dynamic Application Security Testing (DAST)** section, select **Manage profiles**.
1. Select the **Site Profiles** tab.
1. In the profile's row select the **More actions** (**{ellipsis_v}**) menu, then select **Edit**.
1. Edit the fields then select **Save profile**.

### Delete a site profile

Prerequisites:

- If a DAST scan uses the profile, you must be able to push to the branch associated with the scan.

NOTE:
If a site profile is linked to a security policy, a user cannot delete the profile from this page.
See [Scan execution policies](../policies/scan_execution_policies.md) for more information.

To delete a site profile:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure > Security configuration**.
1. In the **Dynamic Application Security Testing (DAST)** section, select **Manage profiles**.
1. Select the **Site Profiles** tab.
1. In the profile's row, select the **More actions** (**{ellipsis_v}**) menu, then select **Delete**.
1. Select **Delete** to confirm the deletion.

### Validate a site profile

Validating a site is required to run an active scan.

Prerequisites:

- A runner must be available in the project to run a validation job.
- The GitLab server's certificate must be trusted and must not use a self-signed certificate.

To validate a site profile:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure > Security configuration**.
1. In the **Dynamic Application Security Testing (DAST)** section, select **Manage profiles**.
1. Select the **Site Profiles** tab.
1. In the profile's row, select **Validate**.
1. Select the validation method.
   1. For **Text file validation**:
      1. Download the validation file listed in **Step 2**.
      1. Upload the validation file to the host, to the location in **Step 3** or any location you
         prefer.
      1. If required, edit the file location in **Step 3**.
      1. Select **Validate**.
   1. For **Header validation**:
      1. Select the clipboard icon in **Step 2**.
      1. Edit the header of the site to validate, and paste the clipboard content.
      1. Select the input field in **Step 3** and enter the location of the header.
      1. Select **Validate**.
   1. For **Meta tag validation**:
      1. Select the clipboard icon in **Step 2**.
      1. Edit the content of the site to validate, and paste the clipboard content.
      1. Select the input field in **Step 3** and enter the location of the meta tag.
      1. Select **Validate**.

The site is validated and an active scan can run against it. A site profile's validation status is
revoked only when it's revoked manually, or its file, header, or meta tag is edited.

### Retry a failed validation

Failed site validation attempts are listed on the **Site profiles** tab of the **Manage profiles**
page.

To retry a site profile's failed validation:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure > Security configuration**.
1. In the **Dynamic Application Security Testing (DAST)** section, select **Manage profiles**.
1. Select the **Site Profiles** tab.
1. In the profile's row, select **Retry validation**.

### Revoke a site profile's validation status

WARNING:
When a site profile's validation status is revoked, all site profiles that share the same URL also
have their validation status revoked.

To revoke a site profile's validation status:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure > Security configuration**.
1. In the **Dynamic Application Security Testing (DAST)** section, select **Manage profiles**.
1. Beside the validated profile, select **Revoke validation**.

The site profile's validation status is revoked.

### Validated site profile headers

The following are code samples of how you can provide the required site profile header in your
application.

#### Ruby on Rails example for on-demand scan

Here's how you can add a custom header in a Ruby on Rails application:

```ruby
class DastWebsiteTargetController < ActionController::Base
  def dast_website_target
    response.headers['Gitlab-On-Demand-DAST'] = '0dd79c9a-7b29-4e26-a815-eaaf53fcab1c'
    head :ok
  end
end
```

#### Django example for on-demand scan

Here's how you can add a
[custom header in Django](https://docs.djangoproject.com/en/2.2/ref/request-response/#setting-header-fields):

```python
class DastWebsiteTargetView(View):
    def head(self, *args, **kwargs):
      response = HttpResponse()
      response['Gitlab-On-Demand-DAST'] = '0dd79c9a-7b29-4e26-a815-eaaf53fcab1c'

      return response
```

#### Node (with Express) example for on-demand scan

Here's how you can add a
[custom header in Node (with Express)](https://expressjs.com/en/5x/api.html#res.append):

```javascript
app.get('/dast-website-target', function(req, res) {
  res.append('Gitlab-On-Demand-DAST', '0dd79c9a-7b29-4e26-a815-eaaf53fcab1c')
  res.send('Respond to DAST ping')
})
```

## Scanner profile

> - Deprecated AJAX Spider option with the introduction of Browser based on-demand DAST scans in GitLab 17.0.
> - Renamed spider timeout to crawl timeout with the introduction of Browser based on-demand DAST scans in GitLab 17.0.

A scanner profile defines the configuration details of a security scanner.

A scanner profile contains:

- **Profile name:** A name you give the scanner profile. For example, "Spider_15". While a scanner
  profile is referenced in either `.gitlab-ci.yml` or an on-demand scan, it **cannot** be renamed.
- **Scan mode:** A passive scan monitors all HTTP messages (requests and responses) sent to the target. An active scan attacks the target to find potential vulnerabilities.
- **Crawl timeout:** The maximum number of minutes allowed for the crawler to traverse the site.
- **Target timeout:** The maximum number of seconds DAST waits for the site to be available before
  starting the scan.
- **Debug messages:** Include debug messages in the DAST console output.

You can reference a scanner profile in `.gitlab-ci.yml` and
on-demand scans.

```yaml
stages:
  - dast

include:
  - template: DAST.gitlab-ci.yml

dast:
  stage: dast
  dast_configuration:
    scanner_profile: "<profile name>"
```

### Create a scanner profile

To create a scanner profile:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure > Security configuration**.
1. In the **Dynamic Application Security Testing (DAST)** section, select **Manage profiles**.
1. Select **New > Scanner profile**.
1. Complete the form. For details of each field, see [Scanner profile](#scanner-profile).
1. Select **Save profile**.

### Edit a scanner profile

Prerequisites:

- If a DAST scan uses the profile, you must be able to push to the branch associated with the scan.

NOTE:
If a scanner profile is linked to a security policy, you cannot edit the profile from this page.
For more information, see [Scan execution policies](../policies/scan_execution_policies.md).

To edit a scanner profile:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure > Security configuration**.
1. In the **Dynamic Application Security Testing (DAST)** section, select **Manage profiles**.
1. Select the **Scanner profiles** tab.
1. In the scanner's row, select the **More actions** (**{ellipsis_v}**) menu, then select **Edit**.
1. Edit the form.
1. Select **Save profile**.

### Delete a scanner profile

Prerequisites:

- If a DAST scan uses the profile, you must be able to push to the branch associated with the scan.

NOTE:
If a scanner profile is linked to a security policy, a user cannot delete the profile from this
page. For more information, see [Scan execution policies](../policies/scan_execution_policies.md).

To delete a scanner profile:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure > Security configuration**.
1. In the **Dynamic Application Security Testing (DAST)** section, select **Manage profiles**.
1. Select the **Scanner profiles** tab.
1. In the scanner's row, select the **More actions** (**{ellipsis_v}**) menu, then select **Delete**.
1. Select **Delete**.

## Auditing

The creation, updating, and deletion of DAST profiles, DAST scanner profiles,
and DAST site profiles are included in the [audit log](../../../administration/audit_event_reports.md).
