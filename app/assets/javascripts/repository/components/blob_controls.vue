<script>
import { GlButton } from '@gitlab/ui';
import { __ } from '~/locale';
import createFlash from '~/flash';
import getRefMixin from '~/repository/mixins/get_ref';
import initSourcegraph from '~/sourcegraph';
import { updateElementsVisibility } from '../utils/dom';
import blobControlsQuery from '../queries/blob_controls.query.graphql';

export default {
  i18n: {
    findFile: __('Find file'),
    blame: __('Blame'),
    history: __('History'),
    permalink: __('Permalink'),
    errorMessage: __('An error occurred while loading the blob controls.'),
  },
  buttonClassList: 'gl-sm-w-auto gl-w-full gl-sm-mt-0 gl-mt-3',
  components: {
    GlButton,
  },
  mixins: [getRefMixin],
  apollo: {
    project: {
      query: blobControlsQuery,
      variables() {
        return {
          projectPath: this.projectPath,
          filePath: this.filePath,
          ref: this.ref,
        };
      },
      skip() {
        return !this.filePath;
      },
      error() {
        createFlash({ message: this.$options.i18n.errorMessage });
      },
    },
  },
  props: {
    projectPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      project: {
        repository: {
          blobs: {
            nodes: [
              {
                findFilePath: null,
                blamePath: null,
                historyPath: null,
                permalinkPath: null,
              },
            ],
          },
        },
      },
    };
  },
  computed: {
    filePath() {
      return this.$route.params.path;
    },
    showBlobControls() {
      return this.filePath && this.$route.name === 'blobPathDecoded';
    },
    blobInfo() {
      return this.project?.repository?.blobs?.nodes[0] || {};
    },
  },
  watch: {
    showBlobControls(shouldShow) {
      updateElementsVisibility('.tree-controls', !shouldShow);
    },
    blobInfo() {
      initSourcegraph();
    },
  },
};
</script>

<template>
  <div v-if="showBlobControls">
    <gl-button data-testid="find" :href="blobInfo.findFilePath" :class="$options.buttonClassList">
      {{ $options.i18n.findFile }}
    </gl-button>
    <gl-button data-testid="blame" :href="blobInfo.blamePath" :class="$options.buttonClassList">
      {{ $options.i18n.blame }}
    </gl-button>

    <gl-button data-testid="history" :href="blobInfo.historyPath" :class="$options.buttonClassList">
      {{ $options.i18n.history }}
    </gl-button>

    <gl-button
      data-testid="permalink"
      :href="blobInfo.permalinkPath"
      :class="$options.buttonClassList"
      class="js-data-file-blob-permalink-url"
    >
      {{ $options.i18n.permalink }}
    </gl-button>
  </div>
</template>
