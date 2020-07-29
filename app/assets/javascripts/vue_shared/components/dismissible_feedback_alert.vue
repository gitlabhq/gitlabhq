<script>
import { GlAlert, GlSprintf, GlLink } from '@gitlab/ui';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import { slugifyWithUnderscore } from '~/lib/utils/text_utility';

export default {
  components: {
    GlAlert,
    GlSprintf,
    GlLink,
    LocalStorageSync,
  },
  props: {
    featureName: {
      type: String,
      required: true,
    },
    feedbackLink: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isDismissed: 'false',
    };
  },
  computed: {
    storageKey() {
      return `${slugifyWithUnderscore(this.featureName)}_feedback_dismissed`;
    },
    showAlert() {
      return this.isDismissed === 'false';
    },
  },
  methods: {
    dismissFeedbackAlert() {
      this.isDismissed = 'true';
    },
  },
};
</script>

<template>
  <div v-show="showAlert">
    <local-storage-sync
      :value="isDismissed"
      :storage-key="storageKey"
      @input="dismissFeedbackAlert"
    />
    <gl-alert v-if="showAlert" class="gl-mt-5" @dismiss="dismissFeedbackAlert">
      <gl-sprintf
        :message="
          __(
            'We’ve been making changes to %{featureName} and we’d love your feedback %{linkStart}in this issue%{linkEnd} to help us improve the experience.',
          )
        "
      >
        <template #featureName>{{ featureName }}</template>
        <template #link="{ content }">
          <gl-link :href="feedbackLink" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </gl-alert>
  </div>
</template>
