import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
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
            draftsForFile: () => () => [{ id: 1 }, { id: 2 }],
          },
        },
      },
    });

    vm = shallowMount(DiffFileDrafts, {
      store,
      propsData: { fileHash: 'filehash' },
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
