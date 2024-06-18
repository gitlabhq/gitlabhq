<script>
import { GlLink, GlTooltipDirective, GlIcon } from '@gitlab/ui';
import dateFormat from '~/lib/dateformat';
import { getTimeago } from '~/lib/utils/datetime_utility';
import { truncateSha } from '~/lib/utils/text_utility';
import { __, sprintf } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import ExpandButton from '~/vue_shared/components/expand_button.vue';

export default {
  name: 'EvidenceBlock',
  components: {
    ClipboardButton,
    ExpandButton,
    GlLink,
    GlIcon,
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
    evidences() {
      return this.release.evidences;
    },
  },
  methods: {
    evidenceTitle(index) {
      const [tag, evidence, filename] = this.release.evidences[index].filepath.split('/').slice(-3);
      return sprintf(__('%{tag}-%{evidence}-%{filename}'), { tag, evidence, filename });
    },
    evidenceUrl(index) {
      return this.release.evidences[index].filepath;
    },
    sha(index) {
      return this.release.evidences[index].sha;
    },
    shortSha(index) {
      return truncateSha(this.release.evidences[index].sha);
    },
    collectedAt(index) {
      return dateFormat(this.release.evidences[index].collectedAt, 'mmmm dS, yyyy, h:MM TT');
    },
    timeSummary(index) {
      const { format } = getTimeago();
      const summary = sprintf(__(' Collected %{time}'), {
        time: format(this.release.evidences[index].collectedAt),
      });
      return summary;
    },
  },
};
</script>

<template>
  <div>
    <h3 class="gl-heading-5 gl-mb-2!">{{ __('Evidence collection') }}</h3>
    <div v-for="(evidence, index) in evidences" :key="evidenceTitle(index)">
      <div class="gl-flex gl-items-center">
        <gl-link
          v-gl-tooltip
          class="gl-flex gl-items-center gl-font-monospace"
          target="_blank"
          :title="__('Open evidence JSON in new tab')"
          :href="evidenceUrl(index)"
        >
          <gl-icon name="review-list" class="align-middle gl-mr-3" />
          <span>{{ evidenceTitle(index) }}</span>
          <gl-icon name="external-link" class="gl-ml-2 gl-flex-shrink-0 gl-flex-grow-0" />
        </gl-link>

        <expand-button class="gl-flex gl-items-center gl-gap-2 gl-ml-4">
          <template #short>
            <span class="js-short gl-font-monospace gl-text-secondary">{{ shortSha(index) }}</span>
          </template>
          <template #expanded>
            <span class="js-expanded gl-font-monospace gl-pl-2">{{ sha(index) }}</span>
          </template>
        </expand-button>
        <clipboard-button :title="__('Copy evidence SHA')" :text="sha(index)" category="tertiary" />
      </div>

      <div class="gl-flex gl-items-center gl-text-secondary">
        <gl-icon
          v-gl-tooltip
          name="clock"
          class="align-middle gl-mr-3"
          :title="collectedAt(index)"
        />
        <span>{{ timeSummary(index) }}</span>
      </div>
    </div>
  </div>
</template>
