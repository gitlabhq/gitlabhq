<script>
/**
 * This component is a utility that can be used in a HAML settings pages
 * It will get all tooltip targets and create a tooltip for each one.
 * This should not be used in Vue Apps as we we are breaking component isolation.
 * Instead, use `lock_tooltip.vue` and provide a list of vue $refs to loop through.
 */
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import LockTooltip from './lock_tooltip.vue';

export default {
  name: 'HamlLockTooltips',
  components: {
    LockTooltip,
  },
  data() {
    return {
      targets: [],
    };
  },
  mounted() {
    this.targets = [...document.querySelectorAll('.js-cascading-settings-lock-tooltip-target')].map(
      (el) => {
        const {
          dataset: { tooltipData },
        } = el;

        const { lockedByAncestor, lockedByApplicationSetting, ancestorNamespace } =
          convertObjectPropsToCamelCase(JSON.parse(tooltipData || '{}'), { deep: true });

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
    <lock-tooltip
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
