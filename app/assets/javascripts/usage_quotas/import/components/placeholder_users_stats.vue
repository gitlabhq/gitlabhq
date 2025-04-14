<script>
import { GlSingleStat } from '@gitlab/ui/dist/charts';
import { __, formatNumber } from '~/locale';
import HelpPageLink from '~/vue_shared/components/help_page_link/help_page_link.vue';

export default {
  name: 'PlaceholderUsersStats',
  components: { HelpPageLink, GlSingleStat },
  inject: {
    placeholderUsersCount: {
      default: null,
    },
    placeholderUsersLimit: {
      default: 0,
    },
  },
  computed: {
    isUnlimited() {
      return this.placeholderUsersLimit === 0;
    },
    statValue() {
      if (this.isUnlimited) {
        return __('Unlimited');
      }

      return `${formatNumber(this.placeholderUsersCount)} / ${formatNumber(this.placeholderUsersLimit)}`;
    },
  },
};
</script>

<template>
  <div class="gl-grid gl-gap-5 lg:gl-grid-cols-2">
    <div class="gl-border gl-rounded-base gl-border-section gl-bg-section gl-p-5">
      <gl-single-stat :title="s__('UserMapping|Placeholder user limit')" :value="statValue" />
      <p class="gl-mb-0 gl-px-2 gl-text-subtle">
        {{ s__("UserMapping|This limit is shared with all subgroups in the group's hierarchy.") }}
        <help-page-link href="user/project/import/_index" anchor="placeholder-user-limits">{{
          __('Learn more')
        }}</help-page-link
        >.
      </p>
    </div>
  </div>
</template>
