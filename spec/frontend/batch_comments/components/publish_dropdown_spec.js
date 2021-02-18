import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import PreviewDropdown from '~/batch_comments/components/preview_dropdown.vue';
import { createStore } from '~/mr_notes/stores';
import '~/behaviors/markdown/render_gfm';
import { createDraft } from '../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Batch comments publish dropdown component', () => {
  let wrapper;

  function createComponent() {
    const store = createStore();
    store.state.batchComments.drafts.push(createDraft(), { ...createDraft(), id: 2 });

    wrapper = shallowMount(PreviewDropdown, {
      store,
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders list of drafts', () => {
    createComponent();

    expect(wrapper.findAll(GlDropdownItem).length).toBe(2);
  });

  it('renders draft count in dropdown title', () => {
    createComponent();

    expect(wrapper.find(GlDropdown).props('headerText')).toEqual('2 pending comments');
  });
});
