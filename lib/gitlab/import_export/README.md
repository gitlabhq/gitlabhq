# GitLab Import/Export developer documentation

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**

- [GitLab Import/Export developer documentation](#gitlab-importexport-developer-documentation)
  - [Breaking changes](#breaking-changes)
  - [Failing specs](#failing-specs)
    - [Adding a new sensitive word (such as `pass`) will make the feature spec `export_file_spec.rb` to fail.](#adding-a-new-sensitive-word-such-as-pass-will-make-the-feature-spec-export_file_specrb-to-fail)
    - [Adding a new model - `model_configuration_spec.rb`](#adding-a-new-model---model_configuration_specrb)
    - [Adding/Removing attributes - `attribute_configuration_spec.rb`](#addingremoving-attributes---attribute_configuration_specrb)
  - [Bumping the version number](#bumping-the-version-number)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Breaking changes

Breaking changes will involve a version bump on the Import/Export instance. These are:
- Renaming a column
- Renaming an attribute
- Renaming a table name

These won't break the Import/Export, as it's clever enough to ignore them:
- Adding/Removing a column
- Adding/Removing a table

## Failing specs

There are a number of specs that will normally fail and tell you what to do in case something
in the DB has changed that needs an update in the Import/Export.

### Adding a new sensitive word (such as `pass`) will make the feature spec `export_file_spec.rb` to fail.

- You can update the spec to add the model to `safe_list` in case it's fine to export this info.
- Alternatively, you can ignore the attribute in `import_export.yml` (`excluded_attributes` section)

### Adding a new model - `model_configuration_spec.rb`

Because we may want to export and not forget that new model you have added, we have to choose between:

- If we also want to export/import the model, we have to add it to the `import_export.yml`. Make sure
it's at the right level. Also add it to `all_models.yml`, to acknowledge that it has been resolved.
- If you don't want to export the model, add it to `all_models.yml` at the right level. It will simply
be ignored and the test will pass.


### Adding/Removing attributes - `attribute_configuration_spec.rb`

This is mainly a security measure, to make sure that new attributes added to a model will be exported.
The attributes will be exported automatically, but we need to know they are safe to be exported.

- If it's safe to export/import this attributes, simply add them to `safe_model_attributes.yml`
- If you don't want those attributes to be exported/imported, blacklist them in `import_export.yml`
(`excluded_attributes` section)

## Bumping the version number

Due to the dynamic nature of the Import/Export we don't follow a strict semver 
as small non-breaking changes may occur very often with a lof of new additions to the code.

We always bump the patch version (MAJOR.MINOR.PATCH) when there's a breaking change.
The other numbers are reserved for changes in the actual Import/Export, such as refactoring
the code to use a completely different configuration.

1. Update `import_export.rb` with the new version (`Gitlab::ImportExport::VERSION`)
1. Update the version table in the docs to add the new version (`import_export.md`)
1. The `import_file_spec.rb` test may fail after bumping the version. You can update the spec
to use a new generated `test_project_export.tar.gz` by running the following task: 
    ```sh
    bundle exec rake gitlab:import_export:bump_test_version 
    ```
