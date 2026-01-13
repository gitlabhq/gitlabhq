<script>
import { GlSprintf, GlAlert, GlLink } from '@gitlab/ui';
import {
  ALERT_MESSAGES,
  ADMIN_GARBAGE_COLLECTION_TIP,
} from '~/packages_and_registries/container_registry/explorer/constants/index';

export default {
  name: 'ContainerRegistryTagDeleteAlert',
  components: {
    GlSprintf,
    GlAlert,
    GlLink,
  },
  model: {
    prop: 'deleteAlertType',
    event: 'change',
  },
  props: {
    deleteAlertType: {
      type: String,
      default: null,
      required: false,
      validator(value) {
        return !value || ALERT_MESSAGES[value] !== undefined;
      },
    },
    garbageCollectionHelpPagePath: { type: String, required: false, default: '' },
    isAdmin: {
      type: Boolean,
      default: false,
      required: false,
    },
    showAdminTip: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  emits: ['change'],
  computed: {
    deleteAlertConfig() {
      const config = {
        title: '',
        message: '',
        type: 'success',
      };
      if (this.deleteAlertType) {
        [config.type] = this.deleteAlertType.split('_');

        config.message = ALERT_MESSAGES[this.deleteAlertType];

        if (this.showTip(config.type)) {
          config.title = config.message;
          config.message = ADMIN_GARBAGE_COLLECTION_TIP;
        }
      }
      return config;
    },
  },
  methods: {
    showTip(type) {
      return this.isAdmin && type === 'success' && this.showAdminTip;
    },
  },
};
</script>

<template>
  <gl-alert
    v-if="deleteAlertType"
    :variant="deleteAlertConfig.type"
    :title="deleteAlertConfig.title"
    @dismiss="$emit('change', null)"
  >
    <gl-sprintf :message="deleteAlertConfig.message">
      <template #docLink="{ content }">
        <gl-link :href="garbageCollectionHelpPagePath" target="_blank">
          {{ content }}
        </gl-link>
      </template>
    </gl-sprintf>
  </gl-alert>
</template>
