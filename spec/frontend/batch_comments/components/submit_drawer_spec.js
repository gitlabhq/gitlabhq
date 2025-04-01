import { GlDrawer } from '@gitlab/ui';
import { nextTick } from 'vue';
import { createTestingPinia } from '@pinia/testing';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SubmitDrawer from '~/batch_comments/components/submit_drawer.vue';
import PreviewItem from '~/batch_comments/components/preview_item.vue';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { useNotes } from '~/notes/store/legacy_notes';
import { createCustomGetters } from 'helpers/pinia_helpers';
import createStore from '../create_batch_comments_store';

describe('Batch comments review bar component', () => {
  let store;
  let wrapper;
  let pinia;
  let batchCommentsGetters;

  const findDrawer = () => wrapper.findComponent(GlDrawer);
  const findDrawerToggle = () => wrapper.findByTestId('review-drawer-toggle');
  const findDrawerHeading = () => wrapper.findByTestId('reviewer-drawer-heading');
  const findDraftsCountBadge = () => wrapper.findByTestId('reviewer-drawer-drafts-count-badge');

  const createComponent = (draftsCount = 0, sortedDrafts = []) => {
    batchCommentsGetters = {
      draftsCount,
      sortedDrafts,
    };
    store = createStore();

    wrapper = shallowMountExtended(SubmitDrawer, {
      store,
      pinia,
    });
  };

  beforeEach(() => {
    batchCommentsGetters = {};
    pinia = createTestingPinia({
      plugins: [
        globalAccessorPlugin,
        createCustomGetters(() => ({
          batchComments: batchCommentsGetters,
          legacyNotes: {},
          legacyDiffs: {},
        })),
      ],
    });
    useLegacyDiffs();
    useNotes();
  });

  it('toggles drawer when clicking toggle button', async () => {
    createComponent();

    findDrawerToggle().vm.$emit('click');

    await nextTick();

    expect(findDrawer().props('open')).toBe(true);

    findDrawerToggle().vm.$emit('click');

    await nextTick();

    expect(findDrawer().props('open')).toBe(false);
  });

  describe.each`
    draftsCount | heading                  | badgeRenders
    ${0}        | ${'No pending comments'} | ${false}
    ${1}        | ${'1 pending comment'}   | ${true}
    ${2}        | ${'2 pending comments'}  | ${true}
  `('with draftsCount as $draftsCount', ({ draftsCount, heading, badgeRenders }) => {
    it(`renders heading as ${heading}`, () => {
      createComponent(draftsCount);

      expect(findDrawerHeading().text()).toBe(heading);
    });

    it(`${badgeRenders ? 'renders' : 'does not render'} drafts count badge`, () => {
      createComponent(draftsCount);

      expect(findDraftsCountBadge().exists()).toBe(badgeRenders);
    });
  });

  it('renders list of preview items', () => {
    createComponent(1, [{ id: 1 }, { id: 2 }]);

    const previewItems = wrapper.findAllComponents(PreviewItem);

    expect(previewItems).toHaveLength(2);
    expect(previewItems.at(0).props()).toMatchObject(expect.objectContaining({ draft: { id: 1 } }));
    expect(previewItems.at(1).props()).toMatchObject(expect.objectContaining({ draft: { id: 2 } }));
  });
});
