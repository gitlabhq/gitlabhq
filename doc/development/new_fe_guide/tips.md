# Tips

## Clearing production compiled assets

To clear production compiled assets created with `yarn webpack-prod` you can run:

```
yarn clean
```

## Creating feature flags in development

The process for creating a feature flag is the same as [enabling a feature flag in development](../feature_flags.md#enabling-a-feature-flag-in-development).

Your feature flag can now be:

- [made available to the frontend](../feature_flags.md#frontend) via the `gon`
- queried in [tests](../feature_flags.md#specs)
- queried in HAML templates and ruby files via the `Feature.enabled?(:my_shiny_new_feature_flag)` method

### More on feature flags

- [Deleting a feature flag](../../api/features.md#delete-a-feature)
- [Manage feature flags](../feature_flags.md)
- [Feature flags API](../../api/features.md)
