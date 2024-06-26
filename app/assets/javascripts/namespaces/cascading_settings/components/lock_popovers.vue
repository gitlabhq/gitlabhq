<script>
import { GlPopover, GlSprintf, GlLink } from '@gitlab/ui';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { s__ } from '~/locale';

export default {
  name: 'LockPopovers',
  i18n: {
    popoverTitle: s__('CascadingSettings|Setting cannot be changed'),
    applicationSettingMessage: s__(
      'CascadingSettings|An administrator selected this setting for the instance and you cannot change it.',
    ),
    ancestorSettingMessage: s__(
      'CascadingSettings|This setting has been enforced by an owner of %{link}.',
    ),
  },
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
        <template #title>{{ $options.i18n.popoverTitle }}</template>
        <span data-testid="cascading-settings-lock-popover">
          <template v-if="lockedByApplicationSetting">{{
            $options.i18n.applicationSettingMessage
          }}</template>
          <gl-sprintf
            v-else-if="lockedByAncestor && ancestorNamespace"
            :message="$options.i18n.ancestorSettingMessage"
          >
            <template #link>
              <gl-link :href="ancestorNamespace.path" class="gl-font-sm">{{
                ancestorNamespace.fullName
              }}</gl-link>
            </template>
          </gl-sprintf>
        </span>
      </gl-popover>
    </template>
  </div>
</template>
