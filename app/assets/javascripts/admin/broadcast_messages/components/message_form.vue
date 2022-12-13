<script>
import {
  GlButton,
  GlBroadcastMessage,
  GlForm,
  GlFormCheckbox,
  GlFormCheckboxGroup,
  GlFormInput,
  GlFormSelect,
  GlFormText,
  GlFormTextarea,
} from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { s__ } from '~/locale';
import { createAlert, VARIANT_DANGER } from '~/flash';
import { redirectTo } from '~/lib/utils/url_utility';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { BROADCAST_MESSAGES_PATH, THEMES, TYPES, TYPE_BANNER } from '../constants';
import MessageFormGroup from './message_form_group.vue';
import DatetimePicker from './datetime_picker.vue';

const FORM_HEADERS = { headers: { 'Content-Type': 'application/json; charset=utf-8' } };

export default {
  name: 'MessageForm',
  components: {
    DatetimePicker,
    GlButton,
    GlBroadcastMessage,
    GlForm,
    GlFormCheckbox,
    GlFormCheckboxGroup,
    GlFormInput,
    GlFormSelect,
    GlFormText,
    GlFormTextarea,
    MessageFormGroup,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: ['targetAccessLevelOptions'],
  i18n: {
    message: s__('BroadcastMessages|Message'),
    messagePlaceholder: s__('BroadcastMessages|Your message here'),
    type: s__('BroadcastMessages|Type'),
    theme: s__('BroadcastMessages|Theme'),
    dismissable: s__('BroadcastMessages|Dismissable'),
    dismissableDescription: s__('BroadcastMessages|Allow users to dismiss the broadcast message'),
    targetRoles: s__('BroadcastMessages|Target roles'),
    targetRolesDescription: s__(
      'BroadcastMessages|The broadcast message displays only to users in projects and groups who have these roles.',
    ),
    targetPath: s__('BroadcastMessages|Target Path'),
    targetPathDescription: s__('BroadcastMessages|Paths can contain wildcards, like */welcome'),
    startsAt: s__('BroadcastMessages|Starts at'),
    endsAt: s__('BroadcastMessages|Ends at'),
    add: s__('BroadcastMessages|Add broadcast message'),
    addError: s__('BroadcastMessages|There was an error adding broadcast message.'),
    update: s__('BroadcastMessages|Update broadcast message'),
    updateError: s__('BroadcastMessages|There was an error updating broadcast message.'),
  },
  messageThemes: THEMES,
  messageTypes: TYPES,
  props: {
    broadcastMessage: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      loading: false,
      message: this.broadcastMessage.message,
      type: this.broadcastMessage.broadcastType,
      theme: this.broadcastMessage.theme,
      dismissable: this.broadcastMessage.dismissable || false,
      targetPath: this.broadcastMessage.targetPath,
      targetAccessLevels: this.broadcastMessage.targetAccessLevels,
      targetAccessLevelOptions: this.targetAccessLevelOptions.map(([text, value]) => ({
        text,
        value,
      })),
      startsAt: new Date(this.broadcastMessage.startsAt.getTime()),
      endsAt: new Date(this.broadcastMessage.endsAt.getTime()),
    };
  },
  computed: {
    isBanner() {
      return this.type === TYPE_BANNER;
    },
    messageBlank() {
      return this.message.trim() === '';
    },
    messagePreview() {
      return this.messageBlank ? this.$options.i18n.messagePlaceholder : this.message;
    },
    isAddForm() {
      return !this.broadcastMessage.id;
    },
    formPath() {
      return this.isAddForm
        ? BROADCAST_MESSAGES_PATH
        : `${BROADCAST_MESSAGES_PATH}/${this.broadcastMessage.id}`;
    },
    formPayload() {
      return JSON.stringify({
        message: this.message,
        broadcast_type: this.type,
        theme: this.theme,
        dismissable: this.dismissable,
        target_path: this.targetPath,
        target_access_levels: this.targetAccessLevels,
        starts_at: this.startsAt.toISOString(),
        ends_at: this.endsAt.toISOString(),
      });
    },
  },
  methods: {
    async onSubmit() {
      this.loading = true;

      const success = await this.submitForm();
      if (success) {
        redirectTo(BROADCAST_MESSAGES_PATH);
      } else {
        this.loading = false;
      }
    },

    async submitForm() {
      const requestMethod = this.isAddForm ? 'post' : 'patch';

      try {
        await axios[requestMethod](this.formPath, this.formPayload, FORM_HEADERS);
      } catch (e) {
        const message = this.isAddForm
          ? this.$options.i18n.addError
          : this.$options.i18n.updateError;
        createAlert({ message, variant: VARIANT_DANGER });
        return false;
      }
      return true;
    },
  },
};
</script>
<template>
  <gl-form @submit.prevent="onSubmit">
    <gl-broadcast-message class="gl-my-6" :type="type" :theme="theme" :dismissible="dismissable">
      {{ messagePreview }}
    </gl-broadcast-message>

    <message-form-group :label="$options.i18n.message" label-for="message-textarea">
      <gl-form-textarea
        id="message-textarea"
        v-model="message"
        size="sm"
        :placeholder="$options.i18n.messagePlaceholder"
      />
    </message-form-group>

    <message-form-group :label="$options.i18n.type" label-for="type-select">
      <gl-form-select id="type-select" v-model="type" :options="$options.messageTypes" />
    </message-form-group>

    <template v-if="isBanner">
      <message-form-group :label="$options.i18n.theme" label-for="theme-select">
        <gl-form-select
          id="theme-select"
          v-model="theme"
          :options="$options.messageThemes"
          data-testid="theme-select"
        />
      </message-form-group>

      <message-form-group :label="$options.i18n.dismissable" label-for="dismissable-checkbox">
        <gl-form-checkbox
          id="dismissable-checkbox"
          v-model="dismissable"
          class="gl-mt-3"
          data-testid="dismissable-checkbox"
        >
          <span>{{ $options.i18n.dismissableDescription }}</span>
        </gl-form-checkbox>
      </message-form-group>
    </template>

    <message-form-group
      v-if="glFeatures.roleTargetedBroadcastMessages"
      :label="$options.i18n.targetRoles"
      data-testid="target-roles-checkboxes"
    >
      <gl-form-checkbox-group v-model="targetAccessLevels" :options="targetAccessLevelOptions" />
      <gl-form-text>
        {{ $options.i18n.targetRolesDescription }}
      </gl-form-text>
    </message-form-group>

    <message-form-group :label="$options.i18n.targetPath" label-for="target-path-input">
      <gl-form-input id="target-path-input" v-model="targetPath" />
      <gl-form-text>
        {{ $options.i18n.targetPathDescription }}
      </gl-form-text>
    </message-form-group>

    <message-form-group :label="$options.i18n.startsAt">
      <datetime-picker v-model="startsAt" />
    </message-form-group>

    <message-form-group :label="$options.i18n.endsAt">
      <datetime-picker v-model="endsAt" />
    </message-form-group>

    <div class="form-actions gl-mb-3">
      <gl-button
        type="submit"
        variant="confirm"
        :loading="loading"
        :disabled="messageBlank"
        data-testid="submit-button"
      >
        {{ isAddForm ? $options.i18n.add : $options.i18n.update }}
      </gl-button>
    </div>
  </gl-form>
</template>
