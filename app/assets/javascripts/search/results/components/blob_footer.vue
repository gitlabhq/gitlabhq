<script>
import { GlSprintf, GlButton, GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';
import { DEFAULT_FETCH_CHUNKS, DEFAULT_SHOW_CHUNKS } from '~/search/results/constants';
import { EVENT_CLICK_BLOB_RESULTS_SHOW_MORE_LESS } from '~/search/results/tracking';
import { InternalEvents } from '~/tracking';
import eventHub from '../event_hub';

const trackingMixin = InternalEvents.mixin();

export default {
  name: 'BlobFooter',
  components: {
    GlSprintf,
    GlButton,
    GlLink,
  },
  mixins: [trackingMixin],
  i18n: {
    showMore: s__('GlobalSearch|Show %{matches} more matches'),
    showLess: s__('GlobalSearch|Show less'),
    showMoreInFile: s__(
      'GlobalSearch|%{lessButtonStart}Show less%{lessButtonEnd} - Too many matches found. Showing %{showingMatches} chunks out of %{fileMatches} results. %{fileLinkStart}Open the file to view all.%{fileLinkEnd}',
    ),
  },
  props: {
    file: {
      type: Object,
      required: true,
    },
    position: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      showMore: false,
      filePath: this.file?.path,
      projectPath: this.file?.projectPath,
      fileLink: this.file.url,
      fileMatchCountTotal: this.file.matchCountTotal,
    };
  },
  computed: {
    howMuchMore() {
      if (this.matchesTotal <= this.showingMatches) {
        return 0;
      }
      return this.matchesTotal - this.showingMatches;
    },
    chunksTotal() {
      return this.file.chunks.length;
    },
    showingChunks() {
      const maxChunksToShow =
        this.chunksTotal < DEFAULT_FETCH_CHUNKS ? this.chunksTotal : DEFAULT_FETCH_CHUNKS;
      return this.showMore ? maxChunksToShow : DEFAULT_SHOW_CHUNKS;
    },
    showingMatches() {
      return this.file.chunks
        .slice(0, this.showingChunks)
        .reduce((acc, chunk) => acc + chunk.matchCountInChunk, 0);
    },
    matchesTotal() {
      return this.file.chunks.reduce((acc, chunk) => acc + chunk.matchCountInChunk, 0);
    },
    hasMoreWeCanShow() {
      return (
        this.showingChunks >= DEFAULT_FETCH_CHUNKS && this.fileMatchCountTotal > this.matchesTotal
      );
    },
  },
  methods: {
    toggleShowMore() {
      eventHub.$emit('showMore', {
        id: `${this.projectPath}:${this.filePath}`,
        state: (this.showMore = !this.showMore),
      });
      this.trackEvent(EVENT_CLICK_BLOB_RESULTS_SHOW_MORE_LESS, {
        label: `${this.position}`,
        property: this.showMore ? 'open' : 'close',
      });
    },
  },
  DEFAULT_FETCH_CHUNKS,
  DEFAULT_SHOW_CHUNKS,
};
</script>

<template>
  <div v-if="!showMore" data-testid="showing-less">
    <gl-button category="tertiary" size="medium" @click="toggleShowMore">
      <gl-sprintf :message="$options.i18n.showMore">
        <template #matches>
          <span>{{ howMuchMore }}</span>
        </template>
      </gl-sprintf>
    </gl-button>
  </div>
  <div v-else-if="hasMoreWeCanShow" data-testid="has-more-we-show">
    <gl-sprintf :message="$options.i18n.showMoreInFile">
      <template #fileMatches
        ><span>{{ fileMatchCountTotal }}</span></template
      >
      <template #showingMatches>{{ showingMatches }}</template>
      <template #fileLink="{ content }"
        ><gl-link :href="fileLink" target="_blank" data-testid="file-link">{{
          content
        }}</gl-link></template
      >
      <template #lessButton="{ content }"
        ><gl-button category="tertiary" size="medium" @click="toggleShowMore">{{
          content
        }}</gl-button>
      </template>
    </gl-sprintf>
  </div>
  <div v-else data-testid="showing-all">
    <gl-button category="tertiary" size="medium" @click="toggleShowMore">
      {{ $options.i18n.showLess }}
    </gl-button>
  </div>
</template>
