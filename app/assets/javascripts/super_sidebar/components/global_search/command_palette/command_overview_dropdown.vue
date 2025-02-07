<script>
import { GlButton, GlCollapsibleListbox, GlSprintf } from '@gitlab/ui';
import { getModifierKey } from '~/constants';
import { InternalEvents } from '~/tracking';
import { s__ } from '~/locale';
import { EVENT_CLICK_COMMANDS_SUB_MENU_IN_COMMAND_PALETTE } from '~/super_sidebar/components/global_search/tracking_constants';

const trackingMixin = InternalEvents.mixin();

export default {
  name: 'CommandsOverviewDropdown',
  components: { GlButton, GlCollapsibleListbox, GlSprintf },
  mixins: [trackingMixin],
  i18n: {
    header: s__("GlobalSearch|I'm looking for"),
    button: s__('GlobalSearch|Commands %{superKey} %{link2Start}k%{link2End}'),
  },
  props: {
    items: {
      type: Array,
      required: true,
    },
  },
  computed: {
    modKey() {
      return getModifierKey(true);
    },
  },
  methods: {
    emitSelected(selected) {
      this.$emit('selected', selected);
    },
    emitHidden() {
      this.$emit('hidden');
    },
    open() {
      this.$refs.commandsDropdown.open();
    },
    close() {
      this.$refs.commandsDropdown.close();
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
      @shown="trackEvent($options.EVENT_CLICK_COMMANDS_SUB_MENU_IN_COMMAND_PALETTE)"
      @hidden="emitHidden"
    >
      <template #toggle>
        <gl-button size="small" category="tertiary">
          <gl-sprintf :message="$options.i18n.button">
            <template #superKey>
              <kbd class="vertical-align-normalization gl-py-2 gl-text-base">{{ modKey }}</kbd>
            </template>
            <template #link2="{ content }">
              <kbd class="vertical-align-normalization gl-py-2 gl-text-base">{{ content }}</kbd>
            </template>
          </gl-sprintf>
        </gl-button>
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
