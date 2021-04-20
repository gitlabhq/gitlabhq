---
stage: none
group: Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Tips

## Clearing production compiled assets

To clear production compiled assets created with `yarn webpack-prod` you can run:

```shell
yarn clean
```

## Creating feature flags in development

The process for creating a feature flag is the same as [enabling a feature flag in development](../feature_flags/index.md#enabling-a-feature-flag-locally-in-development).

Your feature flag can now be:

- [Made available to the frontend](../feature_flags/index.md#frontend) via the `gon`
- Queried in [tests](../feature_flags/index.md#feature-flags-in-tests)
- Queried in HAML templates and Ruby files via the `Feature.enabled?(:my_shiny_new_feature_flag)` method

### More on feature flags

- [Deleting a feature flag](../../api/features.md#delete-a-feature)
- [Manage feature flags](https://about.gitlab.com/handbook/product-development-flow/feature-flag-lifecycle/)
- [Feature flags API](../../api/features.md)

## Running tests locally

This can be done as outlined by the [frontend testing guide](../testing_guide/frontend_testing.md#running-frontend-tests).
