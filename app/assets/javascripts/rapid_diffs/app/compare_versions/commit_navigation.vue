<script>
import { GlLink, GlButton } from '@gitlab/ui';
import { __ } from '~/locale';
import { removeParams } from '~/lib/utils/url_utility';

export default {
  name: 'CommitNavigation',
  components: {
    GlLink,
    GlButton,
  },
  props: {
    commit: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      latestVersionUrl: removeParams(['commit_id']),
    };
  },
  i18n: {
    viewingCommit: __('Viewing commit'),
    showLatestVersion: __('Show latest version'),
  },
};
</script>

<template>
  <div class="gl-flex gl-items-center gl-gap-3">
    <div>
      {{ $options.i18n.viewingCommit }}
      <gl-link :href="commit.commit_url" class="gl-font-monospace">{{ commit.short_id }}</gl-link>
    </div>
    <gl-button :href="latestVersionUrl" size="small" class="gl-shrink-0">
      {{ $options.i18n.showLatestVersion }}
    </gl-button>
  </div>
</template>
