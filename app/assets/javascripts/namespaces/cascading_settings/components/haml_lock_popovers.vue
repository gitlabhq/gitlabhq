<script>
/**
 * This component is a utility that can be used in a HAML settings pages
 * It will get all popover targets and create a popover for each one.
 * This should not be used in Vue Apps as we we are breaking component isolation.
 * Instead, use `lock_popover.vue` and provide a list of vue $refs to loop through.
 */
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import LockPopover from './lock_popover.vue';

export default {
  name: 'HamlLockPopovers',
  components: {
    LockPopover,
  },
  data() {
    return {
      targets: [],
    };
  },
  mounted() {
    this.targets = [...document.querySelectorAll('.js-cascading-settings-lock-popover-target')].map(
      (el) => {
        const {
          dataset: { popoverData },
        } = el;

        const { lockedByAncestor, lockedByApplicationSetting, ancestorNamespace } =
          convertObjectPropsToCamelCase(JSON.parse(popoverData || '{}'), { deep: true });

        return {
          el,
          lockedByAncestor,
          lockedByApplicationSetting,
          ancestorNamespace,
        };
      },
    );
  },
};
</script>

<template>
  <div>
    <lock-popover
      v-for="(
        { el, lockedByApplicationSetting, lockedByAncestor, ancestorNamespace }, index
      ) in targets"
      :key="index"
      :ancestor-namespace="ancestorNamespace"
      :target-element="el"
      :is-locked-by-group-ancestor="lockedByAncestor"
      :is-locked-by-admin="lockedByApplicationSetting"
    />
  </div>
</template>
