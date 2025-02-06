---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Trello Power-Ups
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can use Trello Power-Ups for GitLab to attach
GitLab merge requests to Trello cards.

![GitLab Trello Power-Ups - Trello card](img/trello_card_with_gitlab_powerup_v9_4.png)

## Configure Power-Ups

To configure Power-Ups for a Trello board:

1. Go to your Trello board.
1. Select **Power-Ups** and find the **GitLab** row.
1. Select **Enable**.
1. Select **Settings** (the gear icon).
1. Select **Authorize Account**.
1. Enter the [GitLab API URL](#get-the-api-url) and [personal access token](../user/profile/personal_access_tokens.md#create-a-personal-access-token) with the **API** scope.
1. Select **Save**.

## Get the API URL

Your API URL is your GitLab instance URL with `/api/v4` appended at the end of the URL.
For example, if your GitLab instance URL is `https://gitlab.com`, your API URL is `https://gitlab.com/api/v4`.
If your instance URL is `https://example.com`, your API URL is `https://example.com/api/v4`.
