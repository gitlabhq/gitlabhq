<script>
import { GlLink, GlTooltipDirective } from '@gitlab/ui';
import { INSTANCE_TYPE, GROUP_TYPE, PROJECT_TYPE, I18N_ADMIN } from '../../constants';

export default {
  components: {
    GlLink,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    runner: {
      type: Object,
      required: true,
    },
  },
  computed: {
    cell() {
      switch (this.runner?.runnerType) {
        case INSTANCE_TYPE:
          return {
            text: I18N_ADMIN,
          };
        case GROUP_TYPE: {
          const { name, fullName, webUrl } = this.runner?.groups?.nodes[0] || {};

          return {
            text: name,
            href: webUrl,
            tooltip: fullName !== name ? fullName : '',
          };
        }
        case PROJECT_TYPE: {
          const { name, nameWithNamespace, webUrl } = this.runner?.ownerProject || {};

          return {
            text: name,
            href: webUrl,
            tooltip: nameWithNamespace !== name ? nameWithNamespace : '',
          };
        }
        default:
          return {};
      }
    },
  },
};
</script>

<template>
  <div>
    <gl-link v-if="cell.href" v-gl-tooltip="cell.tooltip" :href="cell.href" class="gl-text-default">
      {{ cell.text }}
    </gl-link>
    <span v-else>{{ cell.text }}</span>
  </div>
</template>
