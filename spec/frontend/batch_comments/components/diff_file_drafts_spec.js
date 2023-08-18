import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import DiffFileDrafts from '~/batch_comments/components/diff_file_drafts.vue';
import DraftNote from '~/batch_comments/components/draft_note.vue';
import DesignNotePin from '~/vue_shared/components/design_management/design_note_pin.vue';

Vue.use(Vuex);

describe('Batch comments diff file drafts component', () => {
  let vm;

  function factory() {
    const store = new Vuex.Store({
      modules: {
        batchComments: {
          namespaced: true,
          getters: {
            draftsForFile: () => () => [
              { id: 1, position: { position_type: 'file' } },
              { id: 2, position: { position_type: 'file' } },
            ],
          },
        },
      },
    });

    vm = shallowMount(DiffFileDrafts, {
      store,
      propsData: { fileHash: 'filehash', positionType: 'file' },
    });
  }

  it('renders list of draft notes', () => {
    factory();

    expect(vm.findAllComponents(DraftNote).length).toEqual(2);
  });

  it('renders index of draft note', () => {
    factory();

    const elements = vm.findAllComponents(DesignNotePin);

    expect(elements.length).toEqual(2);

    expect(elements.at(0).props('label')).toEqual(1);

    expect(elements.at(1).props('label')).toEqual(2);
  });
});
