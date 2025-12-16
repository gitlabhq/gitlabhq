<script>
import { mapActions, mapGetters } from 'pinia';
import { __ } from '~/locale';
import DiffFileOptionsDropdown from '~/rapid_diffs/app/options_menu/diff_file_options_dropdown.vue';
import { useDiffDiscussions } from '~/rapid_diffs/stores/diff_discussions';

export default {
  name: 'CommitDiffsFileOptionsDropdown',
  components: {
    DiffFileOptionsDropdown,
  },
  props: {
    items: {
      type: Array,
      required: true,
    },
    oldPath: {
      type: String,
      required: true,
    },
    newPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapGetters(useDiffDiscussions, ['findDiscussionsForFile']),
    fileDiscussions() {
      return this.findDiscussionsForFile({
        oldPath: this.oldPath,
        newPath: this.newPath,
      });
    },
    hasDiscussions() {
      return this.fileDiscussions.length > 0;
    },
    discussionsHidden() {
      return this.hasDiscussions && this.fileDiscussions.every((d) => d.hidden);
    },
    groups() {
      const baseGroup = {
        items: this.items,
      };

      if (!this.hasDiscussions) {
        return [baseGroup];
      }

      const toggleGroup = {
        bordered: true,
        items: [
          {
            text: this.discussionsHidden
              ? __('Show comments on this file')
              : __('Hide comments on this file'),
            action: this.toggleComments,
            extraAttrs: {
              'data-testid': 'toggle-comment-button',
            },
          },
        ],
      };

      return [baseGroup, toggleGroup];
    },
  },
  methods: {
    ...mapActions(useDiffDiscussions, ['setFileDiscussionsHidden']),
    toggleComments() {
      this.setFileDiscussionsHidden(this.oldPath, this.newPath, !this.discussionsHidden);
      this.$refs['diff-file-options-dropdown']?.closeAndFocus();
    },
  },
};
</script>

<template>
  <diff-file-options-dropdown ref="diff-file-options-dropdown" :items="groups" />
</template>
