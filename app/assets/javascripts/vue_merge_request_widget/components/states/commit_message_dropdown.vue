<script>
import { GlDisclosureDropdown, GlButtonGroup } from '@gitlab/ui';

export default {
  components: {
    GlButtonGroup,
    GlDisclosureDropdown,
    AiCommitMessage: () =>
      import('ee_component/vue_merge_request_widget/components/ai_commit_message.vue'),
  },
  props: {
    commits: {
      type: Array,
      required: true,
      default: () => [],
    },
    aiCommitMessageEnabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    mrId: {
      type: Number,
      required: false,
      default: null,
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
  <gl-button-group>
    <ai-commit-message
      v-if="aiCommitMessageEnabled"
      :id="mrId"
      button-class="!gl-rounded-br-none !gl-rounded-tr-none"
      @update="(val) => $emit('append', val)"
    />
    <gl-disclosure-dropdown
      placement="bottom-end"
      :toggle-text="__('Use an existing commit message')"
      :category="aiCommitMessageEnabled ? 'primary' : 'tertiary'"
      :items="dropdownItems"
      size="small"
      :text-sr-only="aiCommitMessageEnabled"
      class="mr-commit-dropdown"
    >
      <template v-if="aiCommitMessageEnabled" #header>
        <div
          class="gl-flex gl-items-center gl-border-b-1 gl-border-b-dropdown gl-px-4 gl-py-3 gl-border-b-solid"
        >
          <span class="gl-grow gl-pr-2 gl-text-sm gl-font-bold">
            {{ __('Use an existing commit message') }}
          </span>
        </div>
      </template>
      <template #list-item="{ item }">
        <span class="gl-mr-2">{{ item.extraAttrs.text }}</span>
        {{ item.text }}
      </template>
    </gl-disclosure-dropdown>
  </gl-button-group>
</template>
