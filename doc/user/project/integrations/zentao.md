---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

<!--- start_remove The following content will be removed on remove_date: '2025-08-01' -->

# ZenTao (deprecated)

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

WARNING:
This feature was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/377825) in GitLab 15.7
and is planned for removal in 18.0.
This change is a breaking change.

[ZenTao](https://www.zentao.net/) is a web-based project management platform.

The following versions of ZenTao are supported:

- ZenTao 15.4
- ZenTao Pro 10.2
- ZenTao Biz 5.2
- ZenTao Max 2.2

## Configure ZenTao

This integration requires a ZenTao API secret key.

Complete these steps in ZenTao:

1. Go to your **Admin** page and select **Develop > Application**.
1. Select **Add Application**.
1. Under **Name** and **Code**, enter a name and a code for the new secret key.
1. Under **Account**, select an existing account name.
1. Select **Save**.
1. Copy the generated key to use in GitLab.

## Configure GitLab

Complete these steps in GitLab:

1. Go to your project and select **Settings > Integrations**.
1. Select **ZenTao**.
1. Under **Enable integration**, select the **Active** checkbox.
1. Provide the ZenTao configuration information:
   - **ZenTao Web URL**: The base URL of the ZenTao instance web interface you're linking to this GitLab project (for example, `example.zentao.net`).
   - **ZenTao API URL** (optional): The base URL to the ZenTao instance API. Defaults to the Web URL value if not set.
   - **ZenTao API token**: Use the key you generated when you [configured ZenTao](#configure-zentao).
   - **ZenTao Product ID**: To display issues from a single ZenTao product in a given GitLab project. The Product ID can be found in the ZenTao product page under **Settings > Overview**.

   ![ZenTao settings page](img/zentao_product_id_v14_4.png)

1. Optional. Select **Test settings**.
1. Select **Save changes**.

<!--- end_remove -->
