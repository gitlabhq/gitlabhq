<script>
import DiffGutterToggle from './diff_gutter_toggle.vue';
import DiffLineDiscussions from './diff_line_discussions.vue';

export default {
  name: 'DiffDiscussionRow',
  components: {
    DiffGutterToggle,
    DiffLineDiscussions,
  },
  inject: {
    store: { type: Object },
  },
  props: {
    oldPath: {
      type: String,
      required: true,
    },
    newPath: {
      type: String,
      required: true,
    },
    oldLine: {
      type: Number,
      required: false,
      default: null,
    },
    newLine: {
      type: Number,
      required: false,
      default: null,
    },
    parallel: {
      type: Boolean,
      required: true,
    },
    changed: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['empty', 'highlight', 'clear-highlight'],
  computed: {
    positions() {
      if (!this.parallel || (this.oldLine && this.newLine && !this.changed)) {
        return [this.pos(this.oldLine, this.newLine)];
      }
      return [this.pos(this.oldLine, null), this.pos(null, this.newLine)];
    },
    colspan() {
      if (!this.parallel) return 3;
      return this.positions.length === 1 ? 4 : 2;
    },
    collapsed() {
      return this.positions.every(
        (p) => !this.store.findDiscussionsForPosition(p).some((d) => !d.hidden),
      );
    },
    empty() {
      return this.positions.every((p) => this.store.findDiscussionsForPosition(p).length === 0);
    },
  },
  watch: {
    empty(value) {
      if (value) this.$emit('empty');
    },
  },
  methods: {
    pos(oldLine, newLine) {
      return { oldPath: this.oldPath, newPath: this.newPath, oldLine, newLine };
    },
    allDiscussionsForPosition(position) {
      return this.store.findDiscussionsForPosition(position);
    },
    discussionsForGutter(position) {
      return this.allDiscussionsForPosition(position).filter((d) => !d.isForm);
    },
    visibleDiscussions(position) {
      return this.allDiscussionsForPosition(position).filter((d) => !d.hidden);
    },
    toggle(expanded) {
      this.positions.forEach((p) => this.store.setPositionDiscussionsHidden(p, expanded));
    },
    startThread({ oldPath, newPath, oldLine, newLine }) {
      const pos = { old_line: oldLine, new_line: newLine, type: null };
      this.store.addNewLineDiscussionForm({
        oldPath,
        newPath,
        lineRange: { start: pos, end: pos },
      });
    },
  },
};
</script>

<template>
  <tr
    data-discussion-row="true"
    class="rd-discussion-row"
    :data-collapsed="collapsed ? '' : undefined"
  >
    <td v-for="(position, index) in positions" :key="index" :colspan="colspan" class="gl-relative">
      <diff-gutter-toggle
        :class="{ 'gl-ml-[-1px] gl-mt-[-1px]': !collapsed }"
        :discussions="discussionsForGutter(position)"
        @toggle="toggle"
      />
      <diff-line-discussions
        v-if="visibleDiscussions(position).length"
        :discussions="visibleDiscussions(position)"
        @start-thread="startThread(position)"
        @highlight="$emit('highlight', $event)"
        @clear-highlight="$emit('clear-highlight')"
      />
    </td>
  </tr>
</template>
