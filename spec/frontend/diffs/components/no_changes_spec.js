import Vue from 'vue';
import { GlEmptyState } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import { PiniaVuePlugin } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import NoChanges from '~/diffs/components/no_changes.vue';
import store from '~/mr_notes/stores';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { createMrVersionsMock } from '../mock_data/merge_request_diffs';

jest.mock('~/mr_notes/stores', () => jest.requireActual('helpers/mocks/mr_notes/stores'));

const TEST_TARGET_BRANCH = 'foo';
const TEST_SOURCE_BRANCH = 'dev/update';

Vue.use(PiniaVuePlugin);

describe('Diff no changes empty state', () => {
  let pinia;

  const createComponent = (mountFn = shallowMount) =>
    mountFn(NoChanges, {
      mocks: {
        $store: store,
      },
      propsData: {
        changesEmptyStateIllustration: '',
      },
      pinia,
    });

  beforeEach(() => {
    pinia = createTestingPinia({ plugins: [globalAccessorPlugin] });
    useLegacyDiffs().mergeRequestDiffs = createMrVersionsMock();
    store.reset();

    store.getters.getNoteableData = {
      target_branch: TEST_TARGET_BRANCH,
      source_branch: TEST_SOURCE_BRANCH,
    };
  });

  const findEmptyState = (wrapper) => wrapper.findComponent(GlEmptyState);
  const findMessage = (wrapper) => wrapper.find('[data-testid="no-changes-message"]');

  it('prevents XSS', () => {
    store.getters.getNoteableData = {
      source_branch: '<script>alert("test");</script>',
      target_branch: '<script>alert("test");</script>',
    };

    const wrapper = createComponent();

    expect(wrapper.find('script').exists()).toBe(false);
  });

  describe('Renders', () => {
    it('Show empty state', () => {
      const wrapper = createComponent();

      expect(findEmptyState(wrapper).exists()).toBe(true);
    });

    it.each`
      expectedText                                                            | sourceIndex | targetIndex
      ${`No changes between ${TEST_SOURCE_BRANCH} and ${TEST_TARGET_BRANCH}`} | ${null}     | ${null}
      ${`No changes between ${TEST_SOURCE_BRANCH} and version 1`}             | ${0}        | ${3}
      ${`No changes between version 3 and version 2`}                         | ${1}        | ${2}
      ${`No changes between version 3 and ${TEST_TARGET_BRANCH}`}             | ${1}        | ${-1}
    `(
      'renders text "$expectedText" (sourceIndex=$sourceIndex and targetIndex=$targetIndex)',
      ({ expectedText, targetIndex, sourceIndex }) => {
        if (targetIndex !== null) {
          useLegacyDiffs().startVersion = useLegacyDiffs().mergeRequestDiffs[targetIndex];
        }
        if (sourceIndex !== null) {
          useLegacyDiffs().mergeRequestDiff = useLegacyDiffs().mergeRequestDiffs[sourceIndex];
        }

        const wrapper = createComponent(mount);

        expect(findMessage(wrapper).text()).toBe(expectedText);
      },
    );
  });
});
