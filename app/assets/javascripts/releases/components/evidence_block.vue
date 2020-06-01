<script>
import dateFormat from 'dateformat';
import { GlLink, GlTooltipDirective, GlIcon } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import { truncateSha } from '~/lib/utils/text_utility';
import { getTimeago } from '~/lib/utils/datetime_utility';
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
    <div class="card-text prepend-top-default">
      <b>{{ __('Evidence collection') }}</b>
    </div>
    <div v-for="(evidence, index) in evidences" :key="evidenceTitle(index)" class="mb-2">
      <div class="d-flex align-items-center">
        <gl-link
          v-gl-tooltip
          class="d-flex align-items-center monospace"
          :title="__('Download evidence JSON')"
          :download="evidenceTitle(index)"
          :href="evidenceUrl(index)"
        >
          <gl-icon name="review-list" class="align-middle gl-mr-3" />
          <span>{{ evidenceTitle(index) }}</span>
        </gl-link>

        <expand-button>
          <template #short>
            <span class="js-short monospace">{{ shortSha(index) }}</span>
          </template>
          <template #expanded>
            <span class="js-expanded monospace gl-pl-1-deprecated-no-really-do-not-use-me">{{
              sha(index)
            }}</span>
          </template>
        </expand-button>
        <clipboard-button
          :title="__('Copy evidence SHA')"
          :text="sha(index)"
          css-class="btn-default btn-transparent btn-clipboard"
        />
      </div>

      <div class="d-flex align-items-center text-muted">
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
