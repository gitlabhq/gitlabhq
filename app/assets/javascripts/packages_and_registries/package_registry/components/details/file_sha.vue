<script>
import { s__ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import DetailsRow from '~/vue_shared/components/registry/details_row.vue';
import Tracking from '~/tracking';
import { packageTypeToTrackCategory } from '~/packages_and_registries/package_registry/utils';
import {
  TRACKING_ACTION_COPY_PACKAGE_ASSET_SHA,
  TRACKING_LABEL_PACKAGE_ASSET,
} from '~/packages_and_registries/package_registry/constants';

export default {
  name: 'FileSha',
  components: {
    DetailsRow,
    ClipboardButton,
  },
  mixins: [Tracking.mixin()],
  props: {
    sha: {
      type: String,
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
  },
  i18n: {
    copyButtonTitle: s__('PackageRegistry|Copy SHA'),
  },
  computed: {
    tracking() {
      return {
        category: packageTypeToTrackCategory(this.packageType),
      };
    },
  },
  methods: {
    copySha() {
      this.track(TRACKING_ACTION_COPY_PACKAGE_ASSET_SHA, { label: TRACKING_LABEL_PACKAGE_ASSET });
    },
  },
};
</script>

<template>
  <details-row dashed>
    <div class="gl-px-4">
      {{ title }}:
      {{ sha }}
      <clipboard-button
        :text="sha"
        :title="$options.i18n.copyButtonTitle"
        category="tertiary"
        size="small"
        @click="copySha"
      />
    </div>
  </details-row>
</template>
