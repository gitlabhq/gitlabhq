<script>
import allChangesCommittedSvg from '@gitlab/svgs/dist/illustrations/multi-editor_all_changes_committed_empty.svg';
import { GlBanner } from '@gitlab/ui';

import { s__ } from '~/locale';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';

const I18N_TITLE = s__("Runners|We've made some changes and want your feedback");
const I18N_DESCRIPTION = s__(
  "Runners|We want you to be able to manage your runners easily and efficiently from this page, and we are making changes to get there. Give us feedback on how we're doing!",
);
const I18N_LINK = s__('Runners|Add your feedback in the issue');

// use a data url instead getting it from via HTML data-* attributes to simplify removal of this feature flag
const ILLUSTRATION_URL = `data:image/svg+xml;utf8,${encodeURIComponent(allChangesCommittedSvg)}`;
const ISSUE_URL = 'https://gitlab.com/gitlab-org/gitlab/-/issues/371621';
const STORAGE_KEY = 'runner_list_stacked_layout_feedback_dismissed';

export default {
  components: {
    GlBanner,
    LocalStorageSync,
  },
  data() {
    return {
      isDismissed: false,
    };
  },
  methods: {
    onClose() {
      this.isDismissed = true;
    },
  },
  I18N_TITLE,
  I18N_DESCRIPTION,
  I18N_LINK,
  ILLUSTRATION_URL,
  ISSUE_URL,
  STORAGE_KEY,
};
</script>

<template>
  <div>
    <local-storage-sync v-model="isDismissed" :storage-key="$options.STORAGE_KEY" />
    <gl-banner
      v-if="!isDismissed"
      :svg-path="$options.ILLUSTRATION_URL"
      :title="$options.I18N_TITLE"
      :button-text="$options.I18N_LINK"
      :button-link="$options.ISSUE_URL"
      class="gl-my-5"
      @close="onClose"
    >
      <p>{{ $options.I18N_DESCRIPTION }}</p>
    </gl-banner>
  </div>
</template>
