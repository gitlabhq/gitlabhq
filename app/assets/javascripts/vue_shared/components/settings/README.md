# Policy-enforced setting

`policy_enforced_setting.vue` wraps one setting control and shows when a Policy
Store policy governs it. It is inert until the `policy_store_setting_enforcement`
feature flag is enabled for the project's root group.

## Modes

| Mode of the strongest policy | Slot `disabled` | What renders beside or below the control |
| --- | --- | --- |
| `enforce` | `true` | Lock button with a popover naming the policy and linking to it |
| `warn` | `false` | Notice that the value does not comply, with the author message when present |
| `audit`, or no policy | `false` | Nothing |

Several policies can govern one setting. The component picks the strongest mode
(enforce, then warn, then audit) and lists the other policies in the popover.

## Usage

```vue
<policy-enforced-setting :enforcements="requestAccessEnforcements">
  <template #default="{ disabled, describedBy }">
    <gl-form-checkbox v-model="requestAccessEnabled" :disabled="disabled" :aria-describedby="describedBy">
      {{ s__('ProjectSettings|Users can request access') }}
    </gl-form-checkbox>
  </template>
</policy-enforced-setting>
```

Bind `describedBy` to `aria-describedby` on the control so screen readers announce
the reason with the disabled state. Keep the wrapper outside any `<label>`: the
lock button is interactive and must not sit inside the control's label.

## Data

`enforcements` is an array with one row per governing policy:

```js
{ mode: 'enforce' | 'warn' | 'audit', policy: { name, webPath }, message: String | null }
```

Fetch the rows once per page and pass each wrapped setting its own array. The
project permissions panel exposes a `requestAccessEnforcements` prop for this;
nothing fills it yet, so the wrapper stays silent until the policy lookup lands.

The wrapper only reflects state. Disabling a control in the browser does not stop a
crafted request from changing the setting; the server keeps that responsibility.
