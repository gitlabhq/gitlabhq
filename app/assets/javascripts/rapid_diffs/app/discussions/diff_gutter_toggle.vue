<script>
import { GlTooltipDirective, GlIcon, GlAvatar } from '@gitlab/ui';
import { truncate } from '~/lib/utils/text_utility';
import { n__, __ } from '~/locale';

const COUNT_OF_AVATARS_IN_GUTTER = 3;
const LENGTH_OF_AVATAR_TOOLTIP = 17;
const AVATAR_CLASSES = [
  'gl-z-3 group-hover:gl-left-0 gl-delay-0',
  'gl-z-2 group-hover:gl-left-5 gl-delay-[18ms]',
  'gl-z-1 group-hover:gl-left-7 gl-delay-[25ms]',
  'group-hover:gl-left-9 gl-delay-[37ms]',
];

export default {
  name: 'DiffGutterToggle',
  components: {
    GlIcon,
    GlAvatar,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    discussions: {
      type: Array,
      required: true,
    },
  },
  emits: ['toggle'],
  computed: {
    allNotes() {
      return this.discussions.flatMap((d) => d.notes || []);
    },
    expanded() {
      return this.discussions.some((d) => !d.hidden);
    },
    notesInGutter() {
      return this.allNotes.slice(0, COUNT_OF_AVATARS_IN_GUTTER);
    },
    moreCount() {
      return this.allNotes.length - this.notesInGutter.length;
    },
    moreText() {
      if (this.moreCount === 0) return '';
      return n__('%d more comment', '%d more comments', this.moreCount);
    },
  },
  methods: {
    toggle() {
      this.$emit('toggle', this.expanded);
      this.$nextTick(() => this.$refs.toggle?.focus());
    },
    tooltipText(note) {
      const text =
        note.note?.length > LENGTH_OF_AVATAR_TOOLTIP
          ? truncate(note.note, LENGTH_OF_AVATAR_TOOLTIP)
          : note.note;
      return `${note.author.name}: ${text}`;
    },
  },
  avatarClasses: AVATAR_CLASSES,
  i18n: {
    hideComments: __('Hide comments'),
    showComments: __('Show comments'),
  },
};
</script>

<template>
  <div
    v-if="discussions.length"
    data-gutter-toggle
    class="rd-gutter-toggle gl-absolute -gl-left-[calc(var(--rd-row-intrinsic-height)/2)] -gl-top-[calc(var(--rd-row-intrinsic-height))]"
  >
    <button
      v-if="expanded"
      ref="toggle"
      v-gl-tooltip
      :title="$options.i18n.hideComments"
      type="button"
      :aria-label="$options.i18n.hideComments"
      data-testid="collapse-toggle"
      class="focus-visible:gl-outline-blue-500 gl-flex gl-h-[var(--rd-row-intrinsic-height)] gl-w-[var(--rd-row-intrinsic-height)] gl-cursor-pointer gl-items-center gl-justify-center gl-rounded-full gl-border-0 gl-bg-gray-400 gl-p-0 gl-text-white gl-transition-transform focus:gl-outline-none focus-visible:gl-outline focus-visible:gl-outline-2 focus-visible:gl-outline-offset-2"
      @click="toggle"
    >
      <gl-icon :size="12" name="collapse" class="gl-fill-white" />
    </button>
    <button
      v-else
      ref="toggle"
      type="button"
      class="focus-visible:gl-outline-blue-500 gl-group gl-relative -gl-left-1 -gl-top-1 gl-h-6 gl-w-6 gl-cursor-pointer gl-select-none gl-rounded-full gl-border-0 gl-bg-transparent gl-p-0 gl-align-top focus:gl-outline-none focus-visible:gl-outline focus-visible:gl-outline-2 focus-visible:gl-outline-offset-2"
      @click="toggle"
    >
      <span
        v-for="(note, index) in notesInGutter"
        :key="note.id"
        v-gl-tooltip
        :title="tooltipText(note)"
        data-testid="gutter-avatar"
        class="gl-duration-75 gl-ease-out gl-absolute gl-left-0 gl-top-0 gl-rounded-full gl-bg-default gl-transition-all"
        :class="$options.avatarClasses[index]"
      >
        <gl-avatar :src="note.author.avatar_url" :size="24" class="gl-pointer-events-none" />
      </span>
      <span
        v-if="moreText"
        v-gl-tooltip
        :title="moreText"
        data-testid="more-count"
        class="gl-font-sans gl-duration-75 gl-ease-out gl-absolute gl-left-0 gl-top-0 gl-z-0 gl-flex gl-h-6 gl-min-w-6 gl-items-center gl-justify-center gl-rounded-full gl-border-0 gl-bg-gray-400 gl-text-xs gl-font-bold gl-text-white gl-transition-all"
        :class="$options.avatarClasses[notesInGutter.length]"
      >
        +{{ moreCount }}
      </span>
    </button>
  </div>
</template>
