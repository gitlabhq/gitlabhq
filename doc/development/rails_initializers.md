---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Rails initializers

By default, Rails loads Zeitwerk after the initializers in `config/initializers` are loaded.
Autoloading before Zeitwerk is loaded is now deprecated but because we use a lot of autoloaded
constants in our initializers, we had to move the loading of Zeitwerk earlier than these
initializers.

A side-effect of this is that in the initializers, `config.autoload_paths` is already frozen.

To run an initializer before Zeitwerk is loaded, you need put them in `config/initializers_before_autoloader`.
Ruby files in this folder are loaded in alphabetical order just like the default Rails initializers.

Some examples where you would need to do this are:

1. Modifying Rails' `config.autoload_paths`
1. Changing configuration that Zeitwerk uses, for example, inflections
