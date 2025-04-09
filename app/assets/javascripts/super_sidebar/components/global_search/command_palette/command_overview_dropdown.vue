<script>
import { GlButton, GlCollapsibleListbox, GlTooltipDirective } from '@gitlab/ui';
import { getModifierKey } from '~/constants';
import { InternalEvents } from '~/tracking';
import { s__ } from '~/locale';
import { EVENT_CLICK_COMMANDS_SUB_MENU_IN_COMMAND_PALETTE } from '~/super_sidebar/components/global_search/tracking_constants';

const trackingMixin = InternalEvents.mixin();

export default {
  name: 'CommandsOverviewDropdown',
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: { GlButton, GlCollapsibleListbox },
  mixins: [trackingMixin],
  i18n: {
    header: s__('GlobalSearch|Filters'),
    tooltip: s__('GlobalSearch|Filters %{superKey} + %{link2Start}k%{link2End}'),
  },
  props: {
    items: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      listboxOpen: false,
    };
  },
  computed: {
    formattedTooltip() {
      return this.$options.i18n.tooltip
        .replace('%{superKey}', `<kbd>${getModifierKey()}</kbd>`)
        .replace('%{link2Start}k%{link2End}', '<kbd>k</kbd>');
    },
  },
  methods: {
    emitSelected(selected) {
      this.$emit('selected', selected);
    },
    emitHidden() {
      this.$emit('hidden');
    },
    // eslint-disable-next-line vue/no-unused-properties -- open() is part of the component's public API.
    open() {
      this.$refs.commandsDropdown.open();
    },
    // eslint-disable-next-line vue/no-unused-properties -- close() is part of the component's public API.
    close() {
      this.$refs.commandsDropdown.close();
    },
    onListboxShown() {
      this.listboxOpen = true;
      this.trackEvent(this.$options.EVENT_CLICK_COMMANDS_SUB_MENU_IN_COMMAND_PALETTE);
    },
    onListboxHidden() {
      this.listboxOpen = false;
      this.emitHidden();
    },
  },
  EVENT_CLICK_COMMANDS_SUB_MENU_IN_COMMAND_PALETTE,
};
</script>

<template>
  <div>
    <gl-collapsible-listbox
      ref="commandsDropdown"
      :items="items"
      :header-text="$options.i18n.header"
      category="tertiary"
      @select="emitSelected"
      @shown="onListboxShown"
      @hidden="onListboxHidden"
    >
      <template #toggle>
        <gl-button
          ref="filterButton"
          v-gl-tooltip="{
            title: listboxOpen ? '' : formattedTooltip,
            html: true,
          }"
          icon="filter"
          category="tertiary"
          :aria-label="$options.i18n.header"
        />
      </template>
      <template #header>
        <span class="gl-border-b-1 gl-border-dropdown gl-p-4 gl-border-b-solid">
          {{ $options.i18n.header }}
        </span>
      </template>
      <template #list-item="{ item }">
        <span class="gl-flex gl-items-center gl-justify-between">
          <span data-testid="listbox-item-text">{{ item.text }}</span>
          <kbd>{{ item.value }}</kbd>
        </span>
      </template>
    </gl-collapsible-listbox>
  </div>
</template>
