<script>
import { GlPopover, GlSprintf, GlLink } from '@gitlab/ui';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

export default {
  name: 'LockPopovers',
  components: {
    GlPopover,
    GlSprintf,
    GlLink,
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

        const {
          lockedByAncestor,
          lockedByApplicationSetting,
          ancestorNamespace,
        } = convertObjectPropsToCamelCase(JSON.parse(popoverData || '{}'), { deep: true });

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
    <template
      v-for="(
        { el, lockedByApplicationSetting, lockedByAncestor, ancestorNamespace }, index
      ) in targets"
    >
      <gl-popover
        v-if="lockedByApplicationSetting || lockedByAncestor"
        :key="index"
        :target="el"
        placement="top"
      >
        <template #title>{{ s__('CascadingSettings|Setting enforced') }}</template>
        <p data-testid="cascading-settings-lock-popover">
          <template v-if="lockedByApplicationSetting">{{
            s__('CascadingSettings|This setting has been enforced by an instance admin.')
          }}</template>

          <gl-sprintf
            v-else-if="lockedByAncestor && ancestorNamespace"
            :message="
              s__('CascadingSettings|This setting has been enforced by an owner of %{link}.')
            "
          >
            <template #link>
              <gl-link :href="ancestorNamespace.path" class="gl-font-sm">{{
                ancestorNamespace.fullName
              }}</gl-link>
            </template>
          </gl-sprintf>
        </p>
      </gl-popover>
    </template>
  </div>
</template>
