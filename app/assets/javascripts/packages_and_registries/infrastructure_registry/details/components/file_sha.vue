<script>
import { s__ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import DetailsRow from '~/vue_shared/components/registry/details_row.vue';

export default {
  name: 'FileSha',
  components: {
    DetailsRow,
    ClipboardButton,
  },
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
      />
    </div>
  </details-row>
</template>
