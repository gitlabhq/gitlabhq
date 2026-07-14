## Frontend Tests Principles

- Do not mock JavaScript path helpers imported from `app/assets/javascripts/lib/utils/path_helpers` or `ee/app/assets/javascripts/lib/utils/path_helpers` in Jest tests. You can assume that `gon.current_organization.has_scoped_paths` will be `false` and that `window.gon?.relative_url_root` will be `''` in Jest tests. There may be existing tests for the `relative_url_root` functionality, for these you can use `useConfigurePathHelpers` in `spec/frontend/__helpers__/configure_path_helpers.js`.
