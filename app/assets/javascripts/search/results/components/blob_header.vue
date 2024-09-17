<script>
import { GlLink, GlLabel } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState } from 'vuex';
import GlSafeHtmlDirective from '~/vue_shared/directives/safe_html';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import { s__ } from '~/locale';
import { InternalEvents } from '~/tracking';
import { containsPotentialRegex } from '~/lib/utils/regexp';
import { EVENT_CLICK_CLIPBOARD_BUTTON, EVENT_CLICK_HEADER_LINK } from '~/search/results/tracking';
import { GL_LIGHT } from '~/constants';
import { CODE_THEME_DEFAULT, DEFAULT_HEADER_LABEL_COLOR, CODE_THEME_DARK } from '../constants';

const trackingMixin = InternalEvents.mixin();

export default {
  name: 'BlobHeader',
  components: {
    FileIcon,
    ClipboardButton,
    GlLink,
    GlLabel,
  },
  directives: {
    SafeHtml: GlSafeHtmlDirective,
  },
  mixins: [trackingMixin],
  props: {
    filePath: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: false,
      default: '',
    },
    fileUrl: {
      type: String,
      required: false,
      default: '',
    },
    isHeaderOnly: {
      type: Boolean,
      required: false,
      default: false,
    },
    systemColorScheme: {
      type: String,
      required: true,
    },
  },
  i18n: {
    fileLink: s__('GlobalSearch|Open file in repository'),
    isHeaderOnly: s__('GlobalSearch|File name match only'),
  },
  computed: {
    ...mapState(['query']),
    gfmCopyText() {
      return `\`${this.filePath}\``;
    },
    highlightedFilePath() {
      if (!this?.query?.search) {
        return this.filePath;
      }

      if (containsPotentialRegex(this.query.search)) {
        return this.filePath;
      }

      const regex = new RegExp(`(${this.query.search})`, 'g');
      return this.filePath.replace(
        regex,
        (match, p1) => `<span class="highlight_word ${this.systemMatchCodeTheme}">${p1}</span>`,
      );
    },
    systemMatchCodeTheme() {
      return this.systemColorScheme === GL_LIGHT ? CODE_THEME_DEFAULT : CODE_THEME_DARK;
    },
    codeTheme() {
      return gon?.user_color_scheme || CODE_THEME_DEFAULT;
    },
  },
  methods: {
    trackClipboardClick() {
      this.trackEvent(EVENT_CLICK_CLIPBOARD_BUTTON);
    },
    trackHeaderClick() {
      this.trackEvent(EVENT_CLICK_HEADER_LINK);
    },
  },
  DEFAULT_HEADER_LABEL_COLOR,
};
</script>
<template>
  <div class="file-header-content gl-flex gl-items-center gl-leading-1">
    <file-icon :file-name="filePath" :size="16" aria-hidden="true" css-classes="gl-mr-3" />

    <gl-link
      :href="fileUrl"
      :title="$options.i18n.fileLink"
      :class="codeTheme"
      @click="trackHeaderClick"
    >
      <template v-if="projectPath">
        <strong class="project-path-content" data-testid="project-path-content"
          >{{ projectPath }}:
        </strong>
      </template>

      <strong
        v-safe-html="highlightedFilePath"
        class="file-name-content"
        data-testid="file-name-content"
      ></strong>
    </gl-link>
    <clipboard-button
      :text="filePath"
      :gfm="gfmCopyText"
      :title="__('Copy file path')"
      category="tertiary"
      css-class="gl-mr-2"
      @click="trackClipboardClick"
    />
    <gl-label
      v-if="isHeaderOnly"
      :background-color="$options.DEFAULT_HEADER_LABEL_COLOR"
      :title="$options.i18n.isHeaderOnly"
      class="gl-self-center"
    />
  </div>
</template>
