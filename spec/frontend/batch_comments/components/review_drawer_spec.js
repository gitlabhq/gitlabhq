import { GlDrawer } from '@gitlab/ui';
import Vue from 'vue';
import { createTestingPinia } from '@pinia/testing';
import { PiniaVuePlugin } from 'pinia';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ReviewDrawer from '~/batch_comments/components/review_drawer.vue';
import PreviewItem from '~/batch_comments/components/preview_item.vue';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { useNotes } from '~/notes/store/legacy_notes';
import { useBatchComments } from '~/batch_comments/store';
import createStore from '../create_batch_comments_store';

Vue.use(PiniaVuePlugin);

describe('ReviewDrawer', () => {
  let store;
  let wrapper;
  let pinia;

  const findDrawer = () => wrapper.findComponent(GlDrawer);
  const findDrawerHeading = () => wrapper.findByTestId('reviewer-drawer-heading');

  const createComponent = () => {
    store = createStore();

    wrapper = shallowMountExtended(ReviewDrawer, {
      store,
      pinia,
    });
  };

  beforeEach(() => {
    pinia = createTestingPinia({
      plugins: [globalAccessorPlugin],
    });
    useLegacyDiffs();
    useNotes();
    useBatchComments();
  });

  it('shows drawer', () => {
    useBatchComments().drawerOpened = true;
    createComponent();
    expect(findDrawer().props('open')).toBe(true);
  });

  it('hides drawer', () => {
    createComponent();
    findDrawer().vm.$emit('close');
    expect(useBatchComments().setDrawerOpened).toHaveBeenCalledWith(false);
  });

  describe.each`
    draftsCount | heading
    ${0}        | ${'No pending comments'}
    ${1}        | ${'1 pending comment'}
    ${2}        | ${'2 pending comments'}
  `('with draftsCount as $draftsCount', ({ draftsCount, heading }) => {
    it(`renders heading as ${heading}`, () => {
      useBatchComments().drafts = new Array(draftsCount).fill({});
      createComponent();
      expect(findDrawerHeading().text()).toBe(heading);
    });
  });

  it('renders list of preview items', () => {
    useBatchComments().drafts = [{ id: 1 }, { id: 2 }];
    createComponent();

    const previewItems = wrapper.findAllComponents(PreviewItem);

    expect(previewItems).toHaveLength(2);
    expect(previewItems.at(0).props()).toMatchObject(expect.objectContaining({ draft: { id: 1 } }));
    expect(previewItems.at(1).props()).toMatchObject(expect.objectContaining({ draft: { id: 2 } }));
  });
});
