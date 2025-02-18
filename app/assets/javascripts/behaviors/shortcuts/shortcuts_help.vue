<script>
import { GlModal, GlSearchBoxByType, GlLink, GlSprintf } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { joinPaths } from '../../lib/utils/url_utility';
import { keybindingGroups } from './keybindings';
import Shortcut from './shortcut.vue';

export default {
  components: {
    GlModal,
    GlSearchBoxByType,
    GlLink,
    GlSprintf,
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
    absoluteUserPreferencesPath() {
      return joinPaths(gon.relative_url_root || '/', '/-/profile/preferences');
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
    body-class="shortcut-help-body !gl-p-0"
    :visible="true"
    :hide-footer="true"
    @hidden="$emit('hidden')"
  >
    <div class="gl-sticky gl-top-0 gl-flex gl-items-center gl-bg-white gl-px-5 gl-py-5">
      <gl-search-box-by-type
        v-model.trim="searchTerm"
        :aria-label="$options.i18n.search"
        class="gl-mr-3 gl-w-1/2"
      />
      <span>
        <gl-sprintf
          :message="
            __(
              'Enable or disable keyboard shortcuts in your %{linkStart}user preferences%{linkEnd}.',
            )
          "
        >
          <template #link="{ content }">
            <gl-link :href="absoluteUserPreferencesPath">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </span>
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
        <h3
          class="shortcut-help-mapping-title gl-heading-5 gl-mb-0 gl-mt-4 gl-inline-block gl-w-1/2"
        >
          {{ group.name }}
        </h3>
        <dl class="gl-m-0">
          <div
            v-for="keybinding in group.keybindings"
            :key="keybinding.id"
            class="gl-flex gl-items-center"
          >
            <dt class="gl-w-2/5 gl-shrink-0 gl-pr-4 gl-text-right gl-font-normal">
              <shortcut :shortcuts="keybinding.defaultKeys" />
            </dt>
            <dd class="gl-m-0 gl-w-1/2 gl-shrink-0 gl-grow">
              {{ keybinding.description }}
            </dd>
          </div>
        </dl>
      </section>
    </div>
  </gl-modal>
</template>
