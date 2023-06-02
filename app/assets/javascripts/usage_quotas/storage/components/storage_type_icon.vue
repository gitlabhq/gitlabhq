<script>
import { GlIcon } from '@gitlab/ui';

export default {
  components: { GlIcon },
  props: {
    name: {
      type: String,
      required: false,
      default: '',
    },
  },
  methods: {
    iconName(storageTypeName) {
      const defaultStorageTypeIcon = 'disk';
      const storageTypeIconMap = {
        lfsObjects: 'doc-image',
        snippets: 'snippet',
        repository: 'infrastructure-registry',
        packages: 'package',
      };

      return storageTypeIconMap[`${storageTypeName}`] ?? defaultStorageTypeIcon;
    },
  },
};
</script>
<template>
  <span
    class="gl-display-inline-flex gl-align-items-flex-start gl-justify-content-center gl-min-w-8 gl-pr-2 gl-pt-1"
  >
    <gl-icon :name="iconName(name)" :size="16" class="gl-mt-1" />
  </span>
</template>
