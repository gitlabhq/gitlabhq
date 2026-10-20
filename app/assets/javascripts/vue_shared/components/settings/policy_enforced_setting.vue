<script>
import { uniqueId } from 'lodash-es';
import { GlIcon, GlLink, GlPopover, GlSprintf } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import {
  ENFORCEMENT_MODE_AUDIT,
  ENFORCEMENT_MODE_ENFORCE,
  ENFORCEMENT_MODE_PRECEDENCE,
  ENFORCEMENT_MODE_WARN,
} from './constants';
import { isEnforcementRow } from './utils';

/**
 * Wraps one setting control and reflects the Policy Store policies that govern it.
 *
 * Enforce: the slot receives `disabled: true`, and a lock button beside the
 * control explains which policy manages the setting. Warn: the control stays
 * usable and a notice below it says the value does not comply. Audit or no
 * policy: the slot renders unchanged. Everything is off while the
 * `policy_store_setting_enforcement` feature flag is disabled.
 *
 * The slot scope carries `disabled` and `describedBy`; bind the second to
 * `aria-describedby` on the control so the reason is announced with it.
 */
export default {
  name: 'PolicyEnforcedSetting',
  components: {
    GlIcon,
    GlLink,
    GlPopover,
    GlSprintf,
  },
  mixins: [glFeatureFlagsMixin()],
  i18n: {
    popoverTitle: s__('PolicyEnforcedSetting|Setting managed by policy'),
    managedByPolicy: s__(
      'PolicyEnforcedSetting|This setting is managed by the policy %{policyName} and cannot be changed here.',
    ),
  },
  props: {
    /**
     * One row per policy governing the setting:
     * `{ mode, policy: { name, webPath }, message }`.
     */
    enforcements: {
      type: Array,
      required: false,
      default: () => [],
      validator: (rows) => rows.every(isEnforcementRow),
    },
  },
  computed: {
    // Rows with an unknown mode are dropped rather than sorted first, so a new
    // mode or a malformed row can never hide an enforce row behind it.
    rankedEnforcements() {
      return (this.enforcements ?? [])
        .filter(isEnforcementRow)
        .sort(
          (a, b) =>
            ENFORCEMENT_MODE_PRECEDENCE.indexOf(a.mode) -
            ENFORCEMENT_MODE_PRECEDENCE.indexOf(b.mode),
        );
    },
    primary() {
      if (!this.glFeatures.policyStoreSettingEnforcement) return null;

      return this.rankedEnforcements[0] || null;
    },
    isEnforced() {
      return this.primary?.mode === ENFORCEMENT_MODE_ENFORCE;
    },
    isWarned() {
      return this.primary?.mode === ENFORCEMENT_MODE_WARN;
    },
    isActive() {
      return this.isEnforced || this.isWarned;
    },
    describedBy() {
      return this.isActive ? this.descriptionId : null;
    },
    descriptionId() {
      return uniqueId('policy-enforced-setting-description-');
    },
    triggerId() {
      return uniqueId('policy-enforced-setting-lock-');
    },
    slotScope() {
      return { disabled: this.isEnforced, describedBy: this.describedBy };
    },
    // Audit policies stay silent to the end user, so only the other visible
    // policies are listed, once each.
    otherPolicyNames() {
      const names = this.rankedEnforcements
        .slice(1)
        .filter((row) => row.mode !== ENFORCEMENT_MODE_AUDIT)
        .map((row) => row.policy.name)
        .filter((name) => name !== this.primary.policy.name);

      return [...new Set(names)];
    },
    otherPoliciesText() {
      return sprintf(s__('PolicyEnforcedSetting|Also governed by %{policyNames}.'), {
        policyNames: this.otherPolicyNames.join(', '),
      });
    },
    enforcedAriaLabel() {
      return sprintf(this.$options.i18n.managedByPolicy, { policyName: this.primary.policy.name });
    },
  },
};
</script>

<template>
  <div>
    <slot v-if="!isActive" v-bind="slotScope"></slot>
    <template v-else>
      <div class="gl-flex gl-items-start">
        <slot v-bind="slotScope"></slot>
        <template v-if="isEnforced">
          <!-- Form controls carry a bottom margin, so centre on the first text line instead. -->
          <button
            :id="triggerId"
            type="button"
            class="-gl-mt-2 gl-ml-2 gl-border-0 gl-bg-transparent gl-p-2 gl-leading-0"
            :aria-label="enforcedAriaLabel"
            data-testid="policy-enforced-setting-lock"
          >
            <gl-icon name="lock" variant="disabled" />
          </button>
          <gl-popover
            triggers="hover focus"
            :target="triggerId"
            :title="$options.i18n.popoverTitle"
          >
            <gl-sprintf :message="$options.i18n.managedByPolicy">
              <template #policyName>
                <gl-link
                  :href="primary.policy.webPath"
                  data-testid="policy-enforced-setting-link"
                  >{{ primary.policy.name }}</gl-link
                >
              </template>
            </gl-sprintf>
            <p v-if="otherPolicyNames.length" class="gl-mb-0 gl-mt-3">{{ otherPoliciesText }}</p>
          </gl-popover>
          <span :id="descriptionId" hidden>{{ enforcedAriaLabel }}</span>
        </template>
      </div>
      <p
        v-if="isWarned"
        :id="descriptionId"
        class="gl-mb-0 gl-mt-2 gl-flex gl-items-start gl-gap-2 gl-text-subtle"
        data-testid="policy-enforced-setting-warning"
      >
        <gl-icon name="warning" variant="warning" class="gl-mt-1 gl-shrink-0" />
        <span>
          <span class="gl-block">
            <gl-sprintf
              :message="
                s__(
                  'PolicyEnforcedSetting|This setting does not comply with the policy %{policyName}.',
                )
              "
            >
              <template #policyName>
                <gl-link
                  :href="primary.policy.webPath"
                  data-testid="policy-enforced-setting-link"
                  >{{ primary.policy.name }}</gl-link
                >
              </template>
            </gl-sprintf>
          </span>
          <span v-if="primary.message" class="gl-block">{{ primary.message }}</span>
        </span>
      </p>
    </template>
  </div>
</template>
