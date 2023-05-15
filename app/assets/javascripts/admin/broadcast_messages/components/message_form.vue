<script>
import {
  GlButton,
  GlBroadcastMessage,
  GlForm,
  GlFormGroup,
  GlFormCheckbox,
  GlFormCheckboxGroup,
  GlFormInput,
  GlFormSelect,
  GlFormText,
  GlFormTextarea,
} from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { s__ } from '~/locale';
import { createAlert, VARIANT_DANGER } from '~/alert';
import { redirectTo } from '~/lib/utils/url_utility'; // eslint-disable-line import/no-deprecated
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { THEMES, TYPES, TYPE_BANNER } from '../constants';
import DatetimePicker from './datetime_picker.vue';

const FORM_HEADERS = { headers: { 'Content-Type': 'application/json; charset=utf-8' } };

export default {
  DEFAULT_DEBOUNCE_AND_THROTTLE_MS,
  name: 'MessageForm',
  components: {
    DatetimePicker,
    GlButton,
    GlBroadcastMessage,
    GlForm,
    GlFormGroup,
    GlFormCheckbox,
    GlFormCheckboxGroup,
    GlFormInput,
    GlFormSelect,
    GlFormText,
    GlFormTextarea,
  },
  directives: {
    SafeHtml,
  },
  inject: {
    targetAccessLevelOptions: {
      default: [[]],
    },
    messagesPath: {
      default: '',
    },
    previewPath: {
      default: '',
    },
  },
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
      renderedMessage: '',
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
      return this.messageBlank ? this.$options.i18n.messagePlaceholder : this.renderedMessage;
    },
    isAddForm() {
      return !this.broadcastMessage.id;
    },
    formPath() {
      return this.isAddForm
        ? this.messagesPath
        : `${this.messagesPath}/${this.broadcastMessage.id}`;
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
  watch: {
    message: {
      handler() {
        this.renderPreview();
      },
      immediate: true,
    },
  },
  methods: {
    async onSubmit() {
      this.loading = true;

      const success = await this.submitForm();
      if (success) {
        redirectTo(this.messagesPath); // eslint-disable-line import/no-deprecated
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

    async renderPreview() {
      try {
        const res = await axios.post(this.previewPath, this.formPayload, FORM_HEADERS);
        this.renderedMessage = res.data;
      } catch (e) {
        this.renderedMessage = '';
      }
    },
  },
  safeHtmlConfig: {
    ADD_TAGS: ['use'],
  },
};
</script>
<template>
  <gl-form @submit.prevent="onSubmit">
    <gl-broadcast-message
      class="gl-my-6"
      :type="type"
      :theme="theme"
      :dismissible="dismissable"
      data-testid="preview-broadcast-message"
    >
      <div v-safe-html:[$options.safeHtmlConfig]="messagePreview"></div>
    </gl-broadcast-message>

    <gl-form-group :label="$options.i18n.message" label-for="message-textarea">
      <gl-form-textarea
        id="message-textarea"
        v-model="message"
        size="sm"
        :debounce="$options.DEFAULT_DEBOUNCE_AND_THROTTLE_MS"
        :placeholder="$options.i18n.messagePlaceholder"
        data-testid="message-input"
      />
    </gl-form-group>

    <gl-form-group :label="$options.i18n.type" label-for="type-select">
      <gl-form-select id="type-select" v-model="type" :options="$options.messageTypes" />
    </gl-form-group>

    <template v-if="isBanner">
      <gl-form-group :label="$options.i18n.theme" label-for="theme-select">
        <gl-form-select
          id="theme-select"
          v-model="theme"
          :options="$options.messageThemes"
          data-testid="theme-select"
        />
      </gl-form-group>

      <gl-form-group :label="$options.i18n.dismissable" label-for="dismissable-checkbox">
        <gl-form-checkbox
          id="dismissable-checkbox"
          v-model="dismissable"
          class="gl-mt-3"
          data-testid="dismissable-checkbox"
        >
          <span>{{ $options.i18n.dismissableDescription }}</span>
        </gl-form-checkbox>
      </gl-form-group>
    </template>

    <gl-form-group :label="$options.i18n.targetRoles" data-testid="target-roles-checkboxes">
      <gl-form-checkbox-group v-model="targetAccessLevels" :options="targetAccessLevelOptions" />
      <gl-form-text>
        {{ $options.i18n.targetRolesDescription }}
      </gl-form-text>
    </gl-form-group>

    <gl-form-group :label="$options.i18n.targetPath" label-for="target-path-input">
      <gl-form-input id="target-path-input" v-model="targetPath" />
      <gl-form-text>
        {{ $options.i18n.targetPathDescription }}
      </gl-form-text>
    </gl-form-group>

    <gl-form-group :label="$options.i18n.startsAt">
      <datetime-picker v-model="startsAt" />
    </gl-form-group>

    <gl-form-group :label="$options.i18n.endsAt">
      <datetime-picker v-model="endsAt" />
    </gl-form-group>

    <div class="gl-my-5">
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
