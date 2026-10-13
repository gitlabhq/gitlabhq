---
stage: Security Platform
group: Secrets Manager Application
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Secrets Manager frontend development
ignore_in_report: true
---

The Secrets Manager frontend is a Vue application with Vue Router and Apollo.
It lives at `ee/app/assets/javascripts/ci/secrets/`, and `index.js` mounts `components/secrets_app.vue`.

## Code layout

- `components/secrets_table/`, `components/secret_form/`, and `components/secret_details/` hold the feature components.
- `graphql/queries/` and `graphql/mutations/` hold the GraphQL documents, colocated with the app.
- `router.js` defines the routes, and `constants.js` and `context_config.js` hold the shared configuration.
- The settings toggle component is outside this tree, at `ee/app/assets/javascripts/pages/projects/shared/permissions/secrets_manager/`.
- **New secret** shows only when the user's OpenBao permissions allow creating secrets, from `userPermissions.createSecrets` in the secrets manager status query.
- The UI is read-only when the group or project is blocked, when the database is in strict read-only mode, or when the secrets manager status query returns a `writeDenialReason`. For `TRIAL_REQUIRED`, it also shows an alert that Secrets Manager is disabled until someone starts a trial or enables the add-on.

## Frontend tests

Specs live at `ee/spec/frontend/ci/secrets/`, mirroring the source layout.
Run them with this command:

```shell
yarn jest ee/spec/frontend/ci/secrets/
```

The specs mock the GraphQL layer with `createMockApollo`, so they do not need OpenBao, a license, or enrollment.
You can run the whole suite against a plain GitLab Development Kit (GDK).
Shared fixtures are in `ee/spec/frontend/ci/secrets/mock_data.js`.

You still need the full backend setup when you want to exercise the feature in a browser rather than in a spec.
For details, see [Set up Secrets Manager locally](local_setup.md).

For more general frontend guidance, see:

- [Frontend development guidelines](../fe_guide/_index.md)
- [Frontend testing guide](../testing_guide/frontend_testing.md)
