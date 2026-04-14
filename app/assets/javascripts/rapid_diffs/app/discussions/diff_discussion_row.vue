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
    filePaths: { type: Object },
  },
  props: {
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
  emits: ['empty', 'highlight', 'clear-highlight', 'start-thread'],
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
    regularDiscussionsByPosition() {
      return this.positions.map((p) =>
        this.store.findDiscussionsForPosition(p).filter((d) => !d.isDraft),
      );
    },
    allResolved() {
      return this.regularDiscussionsByPosition.every((discussions) => {
        if (!discussions.length) return true;
        const resolvable = discussions.filter((d) => !d.isForm && d.resolvable);
        return resolvable.length > 0 && resolvable.every((d) => d.resolved);
      });
    },
    allHidden() {
      return this.regularDiscussionsByPosition.every((discussions) =>
        discussions.every((d) => d.hidden),
      );
    },
    hasDrafts() {
      return this.positions.some((p) =>
        this.store.findDiscussionsForPosition(p).some((d) => d.isDraft),
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
    allResolved(resolved) {
      this.positions.forEach((p) => this.store.setPositionDiscussionsHidden(p, resolved));
    },
  },
  methods: {
    pos(oldLine, newLine) {
      const { oldPath, newPath } = this.filePaths;
      return { oldPath, newPath, oldLine, newLine };
    },
    allDiscussionsForPosition(position) {
      return this.store.findDiscussionsForPosition(position);
    },
    discussionsForGutter(index) {
      return this.regularDiscussionsByPosition[index].filter((d) => !d.isForm);
    },
    visibleDiscussions(position) {
      if (this.allHidden) return this.allDiscussionsForPosition(position).filter((d) => d.isDraft);
      return this.allDiscussionsForPosition(position);
    },
    toggle(expanded) {
      this.positions.forEach((p) => this.store.setPositionDiscussionsHidden(p, expanded));
    },
  },
};
</script>

<template>
  <tr
    data-discussion-row="true"
    class="rd-discussion-row"
    :data-collapsed="allHidden && !hasDrafts ? '' : undefined"
  >
    <td v-for="(position, index) in positions" :key="index" :colspan="colspan" class="gl-relative">
      <diff-gutter-toggle
        :class="{ 'gl-ml-[-1px] gl-mt-[-1px]': !allHidden }"
        :discussions="discussionsForGutter(index)"
        :expanded="!allHidden"
        @toggle="toggle"
      />
      <diff-line-discussions
        v-if="visibleDiscussions(position).length"
        :discussions="visibleDiscussions(position)"
        :collapsed="allHidden"
        @start-thread="$emit('start-thread', position)"
        @highlight="$emit('highlight', $event)"
        @clear-highlight="$emit('clear-highlight')"
      />
    </td>
  </tr>
</template>
