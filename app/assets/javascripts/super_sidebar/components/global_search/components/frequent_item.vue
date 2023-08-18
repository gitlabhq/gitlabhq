<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';
import { __ } from '~/locale';

export default {
  name: 'FrequentlyVisitedItem',
  components: {
    GlButton,
    ProjectAvatar,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    item: {
      type: Object,
      required: true,
    },
  },
  methods: {
    onRemove() {
      this.$emit('remove', this.item);
    },
  },
  i18n: {
    remove: __('Remove'),
  },
};
</script>

<template>
  <div class="gl-display-flex gl-align-items-center gl-gap-3">
    <project-avatar
      :project-id="item.id"
      :project-name="item.title"
      :project-avatar-url="item.avatar"
      :size="24"
      aria-hidden="true"
    />

    <div class="gl-flex-grow-1 gl-truncate-end">
      {{ item.title }}
      <div
        v-if="item.subtitle"
        data-testid="subtitle"
        class="gl-font-sm gl-text-gray-500 gl-truncate-end"
      >
        {{ item.subtitle }}
      </div>
    </div>

    <gl-button
      v-gl-tooltip.left
      icon="dash"
      category="tertiary"
      :aria-label="$options.i18n.remove"
      :title="$options.i18n.remove"
      class="show-on-focus-or-hover--target"
      @click.stop.prevent="onRemove"
      @keydown.enter.stop.prevent="onRemove"
    />
  </div>
</template>
