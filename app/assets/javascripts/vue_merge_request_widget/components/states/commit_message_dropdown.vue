<script>
import { GlDisclosureDropdown } from '@gitlab/ui';

export default {
  components: {
    GlDisclosureDropdown,
  },
  props: {
    commits: {
      type: Array,
      required: true,
      default: () => [],
    },
  },
  computed: {
    dropdownItems() {
      return this.commits.map((commit) => ({
        text: commit.title,
        extraAttrs: {
          text: commit.shortId || commit.short_Id,
        },
        action: () => {
          this.$emit('input', commit.message);
        },
      }));
    },
  },
};
</script>

<template>
  <div>
    <gl-disclosure-dropdown
      placement="right"
      toggle-text="Use an existing commit message"
      category="tertiary"
      :items="dropdownItems"
      size="small"
      class="mr-commit-dropdown"
    >
      <template #list-item="{ item }">
        <span class="gl-mr-2">{{ item.extraAttrs.text }}</span>
        {{ item.text }}
      </template>
    </gl-disclosure-dropdown>
  </div>
</template>
