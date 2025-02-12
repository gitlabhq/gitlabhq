import Vue from 'vue';
import store from '~/mr_notes/stores';
import DiffFileTree from '~/diffs/components/diffs_file_tree.vue';

export async function initFileBrowser() {
  const el = document.querySelector('[data-file-browser]');
  const { metadataEndpoint } = el.dataset;

  store.state.diffs.endpointMetadata = metadataEndpoint;
  await store.dispatch('diffs/fetchDiffFilesMeta');

  // eslint-disable-next-line no-new
  new Vue({
    el,
    data() {
      return {
        visible: true,
      };
    },
    store,
    render(h) {
      return h(DiffFileTree, {
        props: { visible: this.visible },
        on: {
          toggled: () => {
            this.visible = !this.visible;
          },
        },
      });
    },
  });
}
