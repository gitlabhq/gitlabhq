# Tips

## Clearing production compiled assets

To clear production compiled assets created with `yarn webpack-prod` you can run:

```
yarn clean
```

## Creating feature flags in development

The process for creating a feature flag is the same as [enabling a feature flag in development](https://docs.gitlab.com/ee/development/feature_flags.html#enabling-a-feature-flag-in-development).

Your feature flag can now be:

- [made available to the frontend](https://docs.gitlab.com/ee/development/feature_flags.html#frontend) via the `gon`
- queried in [tests](https://docs.gitlab.com/ee/development/feature_flags.html#specs)
- queried in HAML templates and ruby files via the `Feature.enabled?(:my_shiny_new_feature_flag)` method

### More on feature flags

- [Deleting a feature flag](https://docs.gitlab.com/ee/api/features.html#delete-a-feature)
- [Manage feature flags](https://docs.gitlab.com/ee/development/feature_flags.html)
- [Feature flags API](https://docs.gitlab.com/ee/api/features.html)
