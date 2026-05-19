<script>
import { GlFormGroup } from '@gitlab/ui';
import { TRIGGER_CONFIG } from '../constants';
import WebhookFormTriggerItem from './webhook_form_trigger_item.vue';
import PushEvents from './push_events.vue';

export default {
  name: 'WebhookFormTriggerList',
  components: {
    GlFormGroup,
    GroupEventsTriggerItems: () =>
      import('ee_component/webhooks/components/group_events_trigger_items.vue'),
    MemberApprovalEventsTriggerItem: () =>
      import('ee_component/webhooks/components/member_approval_events_trigger_item.vue'),
    PushEvents,
    VulnerabilityEventsTriggerItem: () =>
      import('ee_component/webhooks/components/vulnerability_events_trigger_item.vue'),
    WebhookFormTriggerItem,
  },
  props: {
    initialTriggers: {
      type: Object,
      required: true,
      default: () => {},
    },
    hasGroup: {
      type: Boolean,
      required: true,
    },
    isSystemHook: {
      type: Boolean,
      required: false,
      default: false,
    },
    isNewHook: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      triggers: { ...this.initialTriggers },
    };
  },
  computed: {
    filteredTriggerConfig() {
      const triggerKeys = Object.keys(this.triggers);
      return this.$options.TRIGGER_CONFIG.filter(({ key }) => triggerKeys.includes(key));
    },
  },
  TRIGGER_CONFIG,
};
</script>

<template>
  <gl-form-group :label="s__('WebhooksTrigger|Trigger')" label-for="webhook-triggers">
    <p v-if="isSystemHook" class="gl-mb-3 gl-text-subtle">
      {{
        s__(
          'WebhooksTrigger|System hooks are triggered on sets of events like creating a project or adding an SSH key. You can also enable extra triggers, such as push events.',
        )
      }}
    </p>

    <webhook-form-trigger-item
      v-if="isSystemHook"
      v-model="triggers.repositoryUpdateEvents"
      data-testid="repositoryUpdateEvents"
      input-name="hook[repository_update_events]"
      trigger-name="repositoryUpdateEvents"
      :label="s__('WebhooksTrigger|Repository update events')"
      :help-text="s__('WebhooksTrigger|A repository is updated.')"
    />

    <push-events
      :push-events="triggers.pushEvents"
      :strategy="triggers.branchFilterStrategy"
      :is-new-hook="isNewHook"
      :push-events-branch-filter="triggers.pushEventsBranchFilter"
    />

    <webhook-form-trigger-item
      v-for="config in filteredTriggerConfig"
      :key="config.key"
      v-model="triggers[config.key]"
      :data-testid="config.key"
      :input-name="config.inputName"
      :trigger-name="config.key"
      :label="config.label"
      :help-text="config.helpText"
      :help-link-text="config.helpLink && config.helpLink.text"
      :help-link-path="config.helpLink && config.helpLink.path"
      :help-link-anchor="config.helpLink && config.helpLink.anchor"
    />

    <member-approval-events-trigger-item
      v-if="isSystemHook"
      :initial-member-approval-trigger="triggers.memberApprovalEvents"
    />

    <template v-if="hasGroup">
      <group-events-trigger-items
        :initial-member-trigger="triggers.memberEvents"
        :initial-project-trigger="triggers.projectEvents"
        :initial-subgroup-trigger="triggers.subgroupEvents"
      />
    </template>

    <vulnerability-events-trigger-item
      v-if="!isSystemHook"
      :initial-vulnerability-trigger="triggers.vulnerabilityEvents"
    />
  </gl-form-group>
</template>
