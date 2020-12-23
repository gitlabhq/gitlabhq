import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import DiffFileDrafts from '~/batch_comments/components/diff_file_drafts.vue';
import DraftNote from '~/batch_comments/components/draft_note.vue';

const localVue = createLocalVue();

localVue.use(Vuex);

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

    vm = shallowMount(localVue.extend(DiffFileDrafts), {
      store,
      localVue,
      propsData: { fileHash: 'filehash' },
    });
  }

  afterEach(() => {
    vm.destroy();
  });

  it('renders list of draft notes', () => {
    factory();

    expect(vm.findAll(DraftNote).length).toEqual(2);
  });

  it('renders index of draft note', () => {
    factory();

    expect(vm.findAll('.js-diff-notes-index').length).toEqual(2);

    expect(vm.findAll('.js-diff-notes-index').at(0).text()).toEqual('1');

    expect(vm.findAll('.js-diff-notes-index').at(1).text()).toEqual('2');
  });
});
