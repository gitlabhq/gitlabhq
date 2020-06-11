---
stage: Monitor
group: Health
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# GitLab Status Page **(ULTIMATE)**

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/2479) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 12.10.

GitLab Status Page allows you to create and deploy a static website to communicate efficiently to users during an incident.

## How to set up

NOTE: **Note:**
Only AWS S3 is supported as a deploy target.

```mermaid
graph TB
    subgraph GitLab Instance
    issues(issue updates) -- trigger --> middleware(Background job: JSON generation)
    end
    subgraph Cloud Provider
    middleware --saves data --> c1(Cloud Bucket stores JSON file)
    end
    subgraph Status Page
    d(Static Site on CDN) -- fetches data --> c1
    end
```

Setting up a Status Page is pretty painless but there are a few things you need to do.

### Cloud account set up

To use GitLab Status Page you first need to set up your account details for your cloud provider in the operations settings page. Today, only AWS is supported.

1. Within your AWS account, create an AWS access key.
1. Add the following permissions policies:
    - [Create bucket](https://gitlab.com/gitlab-org/status-page/-/blob/master/deploy/etc/s3_create_policy.json).
    - [Update bucket contents](https://gitlab.com/gitlab-org/status-page/-/blob/master/deploy/etc/s3_update_bucket_policy.json) (Remember replace `S3_BUCKET_NAME` with your bucket name).

### Status Page project

To deploy the Status Page to AWS S3 you need to add the Status Page project & configure the necessary CI variables.

1. Fork the [Status Page](https://gitlab.com/gitlab-org/status-page) project. This can also be done via [Repository Mirroring](https://gitlab.com/gitlab-org/status-page#repository-mirroring) which will ensure you get the up-to-date Status Page features.
1. Add the following variables in **Settings > CI/CD > Variables**. (To get these variables from Amazon, use your Amazon Console):
    - `S3_BUCKET_NAME` - name of the Amazon S3 bucket (If a bucket with the provided name doesn't exist, the first pipeline run will create one and configure it for [static website hosting](https://docs.aws.amazon.com/AmazonS3/latest/dev/HostingWebsiteOnS3Setup.html))
    - `AWS_DEFAULT_REGION` - the AWS region
    - `AWS_ACCESS_KEY_ID` - the AWS access key ID
    - `AWS_SECRET_ACCESS_KEY` - the AWS secret
1. Run the pipeline to deploy the Status Page to S3.

### Syncing incidents to the Status Page

Once the CI/CD variables are set, you'll need to set up the Project you want to use for Incident issues:

1. To view the [Operations Settings](../settings/#operations-settings) page, navigate to **{settings}** **Settings > Operations > Status Page**.
1. Fill in your cloud provider's credentials and make sure the **Active** checkbox is checked.
1. Click **Save changes**.

## Status Page UI

The Status Page landing page shows you an overview of the recent incidents. Clicking on an incident will take you to the incident's detail page.

![Status Page landing page](../img/status_page_incidents_v12_10.png)

### Incident detail page

The incident detail page shows detailed information about a particular incident. For example:

- Status on the incident, including when the incident was last updated.
- The incident title, including any emojis.
- The description of the incident, including emojis.
- Any file attachments provided in the incident description or comments with a valid image extension. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/205166) in GitLab 13.1.
- A chronological ordered list of updates to the incident.

![Status Page detail](../img/status_page_detail_v12_10.png)

## How it works

### Publishing Incidents

To publish an Incident, you first need to create an issue in the Project you enabled the Status Page settings in.

Issues are not published to the Status Page by default. Use the `/publish` [quick action](../quick_actions.md) in an issue to publish the issue. Only [project or group owners](../../permissions.md) are permitted to publish issues.

After the quick action is used, a background worker publishes the issue onto the Status Page using the credentials you provided during setup.

Since all incidents are published publicly, user and group mentions are anonymized with `Incident Responder`,
and titles of non-public [GitLab references](../../markdown.md#special-gitlab-references) are removed.

When an Incident is published in the GitLab project, you can access the
details page of the Incident by clicking the **Published on status page** button
displayed under the Incident's title.

![Status Page detail link](../img/status_page_detail_link_v13_1.png)

NOTE: **Note:**
Confidential issues can't be published. If you make a published issue confidential, it will be unpublished.

### Publishing updates

To publish an update to the Incident, update the incident issue's description.

CAUTION: **Caution:**
When referenced issues are changed (e.g. title, confidentiality) the incident they were referenced in are not updated automatically.

### Adding comments

To add comments to the Status Page Incident, create a comment on the incident issue.

When you're ready to publish the comment, add a microphone [award emoji](../../../user/award_emojis.md) reaction (`:microphone` 🎤) to the comment. This marks the comment as one which should be deployed to the Status Page.

CAUTION: **Caution:**
Anyone with access to view the Issue can add an Emoji Award to a comment, so you may want to keep your Issues limited to team members only.

### Changing the Incident status

To change the incident status from `open` to `closed`, close the incident issue within GitLab. This will then be updated shortly on the Status Page website.

## Attachment storage

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/205166) in GitLab 13.1.

Beginning with GitLab 13.1, files attached to incident issue descriptions or
comments are published and unpublished to the status page storage as part of
the [publication flow](#how-it-works).

### Limit

Only 5000 attachments per issue will be transferred to the status page.
