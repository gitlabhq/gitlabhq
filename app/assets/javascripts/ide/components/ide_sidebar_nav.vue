<script>
import { GlTooltipDirective, GlIcon } from '@gitlab/ui';
import { BV_HIDE_TOOLTIP } from '~/lib/utils/constants';
import { SIDE_RIGHT } from '../constants';
import { otherSide } from '../utils';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlIcon,
  },
  props: {
    tabs: {
      type: Array,
      required: true,
    },
    side: {
      type: String,
      required: true,
    },
    currentView: {
      type: String,
      required: false,
      default: '',
    },
    isOpen: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    otherSide() {
      return otherSide(this.side);
    },
  },
  methods: {
    isActiveTab(tab) {
      return this.isOpen && tab.views.some((view) => view.name === this.currentView);
    },
    buttonClasses(tab) {
      return [
        {
          'is-right': this.side === SIDE_RIGHT,
          active: this.isActiveTab(tab),
        },
        ...(tab.buttonClasses || []),
      ];
    },
    clickTab(e, tab) {
      e.currentTarget.blur();
      this.$root.$emit(BV_HIDE_TOOLTIP);

      if (this.isActiveTab(tab)) {
        this.$emit('close');
      } else {
        this.$emit('open', tab.views[0]);
      }
    },
  },
};
</script>
<template>
  <nav class="ide-activity-bar">
    <ul class="list-unstyled">
      <li v-for="tab of tabs" :key="tab.title">
        <button
          v-gl-tooltip="{ container: 'body', placement: otherSide }"
          :title="tab.title"
          :aria-label="tab.title"
          class="ide-sidebar-link"
          :class="buttonClasses(tab)"
          type="button"
          @click="clickTab($event, tab)"
        >
          <gl-icon :size="16" :name="tab.icon" />
        </button>
      </li>
    </ul>
  </nav>
</template>
