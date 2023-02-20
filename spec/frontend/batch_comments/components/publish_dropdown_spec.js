import { GlDisclosureDropdown } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import PreviewDropdown from '~/batch_comments/components/preview_dropdown.vue';
import { createStore } from '~/mr_notes/stores';
import { createDraft } from '../mock_data';

jest.mock('~/behaviors/markdown/render_gfm');

Vue.use(Vuex);

describe('Batch comments publish dropdown component', () => {
  let wrapper;
  const draft = createDraft();

  function createComponent() {
    const store = createStore();
    store.state.batchComments.drafts.push(draft, { ...draft, id: 2 });

    wrapper = shallowMount(PreviewDropdown, {
      store,
      stubs: { GlDisclosureDropdown },
    });
  }

  it('renders list of drafts', () => {
    createComponent();

    expect(wrapper.findComponent(GlDisclosureDropdown).props('items')).toMatchObject([
      draft,
      { ...draft, id: 2 },
    ]);
  });

  it('renders draft count in dropdown title', () => {
    createComponent();

    expect(wrapper.findComponent(GlDisclosureDropdown).text()).toEqual('2 pending comments');
  });
});
