import { GlDisclosureDropdown } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { PiniaVuePlugin } from 'pinia';
import PreviewDropdown from '~/batch_comments/components/preview_dropdown.vue';
import { createStore } from '~/mr_notes/stores';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { useNotes } from '~/notes/store/legacy_notes';
import { useBatchComments } from '~/batch_comments/store';
import { createDraft } from '../mock_data';

jest.mock('~/behaviors/markdown/render_gfm');

Vue.use(Vuex);
Vue.use(PiniaVuePlugin);

describe('Batch comments publish dropdown component', () => {
  let wrapper;
  let pinia;
  const draft = createDraft();

  function createComponent() {
    const store = createStore();

    wrapper = shallowMount(PreviewDropdown, {
      store,
      pinia,
      stubs: { GlDisclosureDropdown },
    });
  }

  beforeEach(() => {
    pinia = createTestingPinia({ plugins: [globalAccessorPlugin] });
    useLegacyDiffs();
    useNotes();
    useBatchComments().drafts = [draft, { ...draft, id: 2 }];
  });

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
