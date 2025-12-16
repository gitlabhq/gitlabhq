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
  TRIGGER_CONFIG,
};
</script>

<template>
  <gl-form-group :label="s__('WebhooksTrigger|Trigger')" label-for="webhook-triggers">
    <push-events
      :push-events="triggers.pushEvents"
      :strategy="triggers.branchFilterStrategy"
      :is-new-hook="isNewHook"
      :push-events-branch-filter="triggers.pushEventsBranchFilter"
    />

    <webhook-form-trigger-item
      v-for="config in $options.TRIGGER_CONFIG"
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

    <template v-if="hasGroup">
      <group-events-trigger-items
        :initial-member-trigger="triggers.memberEvents"
        :initial-project-trigger="triggers.projectEvents"
        :initial-subgroup-trigger="triggers.subgroupEvents"
      />
    </template>

    <vulnerability-events-trigger-item
      :initial-vulnerability-trigger="triggers.vulnerabilityEvents"
    />
  </gl-form-group>
</template>
