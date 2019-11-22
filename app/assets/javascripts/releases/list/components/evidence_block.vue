<script>
import { __, sprintf } from '~/locale';
import { GlLink, GlTooltipDirective } from '@gitlab/ui';
import { truncateSha } from '~/lib/utils/text_utility';
import Icon from '~/vue_shared/components/icon.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import ExpandButton from '~/vue_shared/components/expand_button.vue';

export default {
  name: 'EvidenceBlock',
  components: {
    ClipboardButton,
    ExpandButton,
    GlLink,
    Icon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    release: {
      type: Object,
      required: true,
    },
  },
  computed: {
    evidenceTitle() {
      return sprintf(__('%{tag}-evidence.json'), { tag: this.release.tag_name });
    },
    evidenceUrl() {
      return this.release.assets && this.release.assets.evidence_file_path;
    },
    shortSha() {
      return truncateSha(this.sha);
    },
    sha() {
      return this.release.evidence_sha;
    },
  },
};
</script>

<template>
  <div>
    <div class="card-text prepend-top-default">
      <b>
        {{ __('Evidence collection') }}
      </b>
    </div>
    <div class="d-flex align-items-baseline">
      <gl-link
        v-gl-tooltip
        class="monospace"
        :title="__('Download evidence JSON')"
        :download="evidenceTitle"
        :href="evidenceUrl"
      >
        <icon name="review-list" class="align-top append-right-4" /><span>{{ evidenceTitle }}</span>
      </gl-link>

      <expand-button>
        <template slot="short">
          <span class="js-short monospace">{{ shortSha }}</span>
        </template>
        <template slot="expanded">
          <span class="js-expanded monospace gl-pl-1">{{ sha }}</span>
        </template>
      </expand-button>
      <clipboard-button
        :title="__('Copy commit SHA')"
        :text="sha"
        css-class="btn-default btn-transparent btn-clipboard"
      />
    </div>
  </div>
</template>
