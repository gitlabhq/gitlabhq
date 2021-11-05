<script>
import { GlButton } from '@gitlab/ui';
import { getLocation } from '~/jira_connect/subscriptions/utils';
import { objectToQuery } from '~/lib/utils/url_utility';

export default {
  components: {
    GlButton,
  },
  props: {
    usersPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      location: '',
    };
  },
  computed: {
    usersPathWithReturnTo() {
      if (this.location) {
        const queryParams = {
          return_to: this.location,
        };

        return `${this.usersPath}?${objectToQuery(queryParams)}`;
      }

      return this.usersPath;
    },
  },
  created() {
    this.setLocation();
  },
  methods: {
    async setLocation() {
      this.location = await getLocation();
    },
  },
};
</script>
<template>
  <gl-button category="primary" variant="info" :href="usersPathWithReturnTo" target="_blank">
    <slot>
      {{ s__('Integrations|Sign in to add namespaces') }}
    </slot>
  </gl-button>
</template>
