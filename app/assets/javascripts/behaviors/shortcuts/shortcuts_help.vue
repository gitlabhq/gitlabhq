<script>
import { GlModal, GlSearchBoxByType } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { keybindingGroups } from './keybindings';
import Shortcut from './shortcut.vue';
import ShortcutsToggle from './shortcuts_toggle.vue';

export default {
  components: {
    GlModal,
    GlSearchBoxByType,
    ShortcutsToggle,
    Shortcut,
  },
  data() {
    return {
      searchTerm: '',
    };
  },
  computed: {
    filteredKeybindings() {
      if (!this.searchTerm) {
        return keybindingGroups;
      }

      const search = this.searchTerm.toLocaleLowerCase();

      const mapped = keybindingGroups.map((group) => {
        if (group.name.toLocaleLowerCase().includes(search)) {
          return group;
        }
        return {
          ...group,
          keybindings: group.keybindings.filter((binding) =>
            binding.description.toLocaleLowerCase().includes(search),
          ),
        };
      });

      return mapped.filter((group) => group.keybindings.length);
    },
  },
  i18n: {
    title: __(`Keyboard shortcuts`),
    search: s__(`KeyboardShortcuts|Search keyboard shortcuts`),
    noMatch: s__(`KeyboardShortcuts|No shortcuts matched your search`),
  },
};
</script>
<template>
  <gl-modal
    modal-id="keyboard-shortcut-modal"
    size="lg"
    :title="$options.i18n.title"
    data-testid="modal-shortcuts"
    body-class="shortcut-help-body gl-p-0!"
    :visible="true"
    :hide-footer="true"
    @hidden="$emit('hidden')"
  >
    <div
      class="gl-sticky gl-top-0 gl-py-5 gl-px-5 gl-display-flex gl-align-items-center gl-bg-white"
    >
      <gl-search-box-by-type
        v-model.trim="searchTerm"
        :aria-label="$options.i18n.search"
        class="gl-w-half gl-mr-3"
      />
      <shortcuts-toggle class="gl-w-half gl-ml-3" />
    </div>
    <div v-if="filteredKeybindings.length === 0" class="gl-px-5">
      {{ $options.i18n.noMatch }}
    </div>
    <div v-else class="shortcut-help-container gl-mt-8 gl-px-5 gl-pb-5">
      <section
        v-for="group in filteredKeybindings"
        :key="group.id"
        class="shortcut-help-mapping gl-mb-4"
      >
        <strong class="shortcut-help-mapping-title gl-w-half gl-display-inline-block">
          {{ group.name }}
        </strong>
        <div
          v-for="keybinding in group.keybindings"
          :key="keybinding.id"
          class="gl-display-flex gl-align-items-center"
        >
          <shortcut
            class="gl-w-40p gl-flex-shrink-0 gl-text-right gl-pr-4"
            :shortcuts="keybinding.defaultKeys"
          />
          <div class="gl-w-half gl-flex-shrink-0 gl-flex-grow-1">
            {{ keybinding.description }}
          </div>
        </div>
      </section>
    </div>
  </gl-modal>
</template>
