<script>
import { GlCollapsibleListbox, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  name: 'CommandsOverviewDropdown',
  components: { GlCollapsibleListbox, GlSprintf },
  i18n: {
    header: s__('GlobalSearch|I’m looking for'),
    button: s__('GlobalSearch|Commands %{link1Start}⌘%{link1End} %{link2Start}k%{link2End}'),
  },
  props: {
    items: {
      type: Array,
      required: true,
    },
  },
  methods: {
    emitSelected(selected) {
      this.$emit('selected', selected);
    },
    open() {
      this.$refs.commandsDropdown.open();
    },
    close() {
      this.$refs.commandsDropdown.close();
    },
  },
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
    >
      <template #toggle>
        <button class="gl-border-0 gl-rounded-base">
          <gl-sprintf :message="$options.i18n.button">
            <template #link1="{ content }">
              <kbd class="gl-font-base gl-py-2 vertical-align-normalization">{{ content }}</kbd>
            </template>
            <template #link2="{ content }">
              <kbd class="gl-font-base gl-py-2 vertical-align-normalization">{{ content }}</kbd>
            </template>
          </gl-sprintf>
        </button>
      </template>
      <template #header>
        <span class="gl-p-4 gl-border-b-1 gl-border-b-solid gl-border-gray-200">
          {{ $options.i18n.header }}
        </span>
      </template>
      <template #list-item="{ item }">
        <span class="gl-display-flex gl-align-items-center gl-justify-content-space-between">
          <span data-testid="listbox-item-text">{{ item.text }}</span>
          <kbd>{{ item.value }}</kbd>
        </span>
      </template>
    </gl-collapsible-listbox>
  </div>
</template>
