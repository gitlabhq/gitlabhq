<script>
import { GlIcon, GlSprintf } from '@gitlab/ui';
import { MANIFEST_PENDING_DESTRUCTION_STATUS } from '~/packages_and_registries/dependency_proxy/constants';
import ListItem from '~/vue_shared/components/registry/list_item.vue';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { s__ } from '~/locale';

const SHORT_DIGEST_START_INDEX = 7;
const SHORT_DIGEST_END_INDEX = 14;

export default {
  name: 'ManifestRow',
  components: {
    ClipboardButton,
    GlIcon,
    GlSprintf,
    ListItem,
    TimeagoTooltip,
  },
  props: {
    manifest: {
      type: Object,
      required: true,
    },
    dependencyProxyImagePrefix: {
      type: String,
      default: '',
      required: false,
    },
  },
  computed: {
    name() {
      if (this.containsDigestInImageName) {
        return this.manifest?.imageName.split(':')[0];
      }
      return this.manifest?.imageName;
    },
    imageCopyText() {
      const name = this.manifest?.imageName.replace(':sha256:', '@sha256:') ?? '';
      return `${this.dependencyProxyImagePrefix}/${name}`;
    },
    containsDigestInImageName() {
      return this.manifest?.imageName.includes(':sha256:');
    },
    isErrorStatus() {
      return this.manifest?.status === MANIFEST_PENDING_DESTRUCTION_STATUS;
    },
    disabledRowStyle() {
      return this.isErrorStatus ? 'gl-font-normal gl-text-subtle' : '';
    },
    shortDigest() {
      // digest is in the format `sha256:995efde2e81b21d1ea7066aa77a59298a62a9e9fbb4b77f36c189774ec9b1089`
      // for short digest, remove sha256: from the string, and show only the first 7 char
      return this.manifest.digest?.substring(SHORT_DIGEST_START_INDEX, SHORT_DIGEST_END_INDEX);
    },
  },
  i18n: {
    cachedAgoMessage: s__('DependencyProxy|Cached %{time}'),
    copyImagePathTitle: s__('DependencyProxy|Copy image path'),
    digestLabel: s__('DependencyProxy|Digest: %{shortDigest}'),
    scheduledForDeletion: s__('DependencyProxy|Scheduled for deletion'),
  },
};
</script>

<template>
  <list-item :disabled="isErrorStatus">
    <template #left-primary>
      <span :class="disabledRowStyle">{{ name }}</span>
      <clipboard-button
        class="gl-ml-2"
        :text="imageCopyText"
        :title="$options.i18n.copyImagePathTitle"
        category="tertiary"
      />
    </template>
    <template #left-secondary>
      <span data-testid="manifest-row-short-digest">
        <gl-sprintf :message="$options.i18n.digestLabel">
          <template #shortDigest>
            {{ shortDigest }}
          </template>
        </gl-sprintf>
      </span>
      <span v-if="isErrorStatus" class="gl-ml-4" data-testid="status"
        ><gl-icon name="clock" /> {{ $options.i18n.scheduledForDeletion }}</span
      >
    </template>
    <template #right-primary> &nbsp; </template>
    <template #right-secondary>
      <timeago-tooltip :time="manifest.createdAt" data-testid="cached-message">
        <template #default="{ timeAgo }">
          <gl-sprintf :message="$options.i18n.cachedAgoMessage">
            <template #time>{{ timeAgo }}</template>
          </gl-sprintf>
        </template>
      </timeago-tooltip>
    </template>
  </list-item>
</template>
