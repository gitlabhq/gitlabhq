---
stage: Monitor
group: Monitor
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Templating variables for metrics dashboards **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/214539) in GitLab 13.0.

Templating variables can be used to make your metrics dashboard more versatile.

`templating` is a top-level key in the
[dashboard YAML](yaml.md#dashboard-top-level-properties).
Define your variables in the `variables` key, under `templating`. The value of
the `variables` key should be a hash, and each key under `variables`
defines a templating variable on the dashboard, and may contain alphanumeric and underscore characters.

A variable can be used in a Prometheus query in the same dashboard using the syntax
described [in Using Variables](variables.md).

## `text` variable type

WARNING:
This variable type is an _alpha_ feature, and is subject to change at any time
without prior notice!

For each `text` variable defined in the dashboard YAML, a free text field displays
on the dashboard UI, allowing you to enter a value for each variable.

The `text` variable type supports a simple and a full syntax.

### Simple syntax

This example creates a variable called `variable1`, with a default value
of `default value`:

```yaml
templating:
  variables:
    variable1: 'default value'     # `text` type variable with `default value` as its default.
```

### Full syntax

This example creates a variable called `variable1`, with a default value of `default`.
The label for the text box on the UI is the value of the `label` key:

```yaml
templating:
  variables:
    variable1:                       # The variable name that can be used in queries.
      label: 'Variable 1'            # (Optional) label that will appear in the UI for this text box.
      type: text
      options:
        default_value: 'default'     # (Optional) default value.
```

## `custom` variable type

WARNING:
This variable type is an _alpha_ feature, and is subject to change at any time
without prior notice!

Each `custom` variable defined in the dashboard YAML creates a dropdown
selector on the dashboard UI, allowing you to select a value for each variable.

The `custom` variable type supports a simple and a full syntax.

### Simple syntax

This example creates a variable called `variable1`, with a default value of `value1`.
The dashboard UI displays a dropdown with `value1`, `value2` and `value3`
as the choices.

```yaml
templating:
  variables:
    variable1: ['value1', 'value2', 'value3']
```

### Full syntax

This example creates a variable called `variable1`, with a default value of `value_option_2`.
The label for the text box on the UI is the value of the `label` key.
The dashboard UI displays a dropdown with `Option 1` and `Option 2`
as the choices.

If you select `Option 1` from the dropdown, the variable is replaced with `value option 1`.
Similarly, if you select `Option 2`, the variable is replaced with `value_option_2`:

```yaml
templating:
  variables:
    variable1:                           # The variable name that can be used in queries.
      label: 'Variable 1'                # (Optional) label that will appear in the UI for this dropdown.
      type: custom
      options:
        values:
          - value: 'value option 1'        # The value that will replace the variable in queries.
            text: 'Option 1'               # (Optional) Text that will appear in the UI dropdown.
          - value: 'value_option_2'
            text: 'Option 2'
            default: true                  # (Optional) This option should be the default value of this variable.
```

## `metric_label_values` variable type

WARNING:
This variable type is an _alpha_ feature, and is subject to change at any time
without prior notice!

### Full syntax

This example creates a variable called `variable2`. The values of the dropdown are
all the different values of the `backend` label in the Prometheus series described by
`up{env="production"}`.

```yaml
templating:
  variables:
    variable2:                           # The variable name that can be interpolated in queries.
      label: 'Variable 2'                # (Optional) label that will appear in the UI for this dropdown.
      type: metric_label_values
      options:
        series_selector: 'up{env="production"}'
        label: 'backend'
```
