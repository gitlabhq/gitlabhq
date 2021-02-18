import { GlButton } from '@gitlab/ui';
import { createLocalVue, shallowMount, mount } from '@vue/test-utils';
import Vuex from 'vuex';
import NoChanges from '~/diffs/components/no_changes.vue';
import { createStore } from '~/mr_notes/stores';
import diffsMockData from '../mock_data/merge_request_diffs';

const localVue = createLocalVue();
localVue.use(Vuex);

const TEST_TARGET_BRANCH = 'foo';
const TEST_SOURCE_BRANCH = 'dev/update';

describe('Diff no changes empty state', () => {
  let wrapper;
  let store;

  function createComponent(mountFn = shallowMount) {
    wrapper = mountFn(NoChanges, {
      localVue,
      store,
      propsData: {
        changesEmptyStateIllustration: '',
      },
    });
  }

  beforeEach(() => {
    store = createStore();
    store.state.diffs.mergeRequestDiff = {};
    store.state.notes.noteableData = {
      target_branch: TEST_TARGET_BRANCH,
      source_branch: TEST_SOURCE_BRANCH,
    };
    store.state.diffs.mergeRequestDiffs = diffsMockData;
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findMessage = () => wrapper.find('[data-testid="no-changes-message"]');

  it('prevents XSS', () => {
    store.state.notes.noteableData = {
      source_branch: '<script>alert("test");</script>',
      target_branch: '<script>alert("test");</script>',
    };

    createComponent();

    expect(wrapper.find('script').exists()).toBe(false);
  });

  describe('Renders', () => {
    it('Show create commit button', () => {
      createComponent();

      expect(wrapper.find(GlButton).exists()).toBe(true);
    });

    it.each`
      expectedText                                                            | sourceIndex                       | targetIndex
      ${`No changes between ${TEST_SOURCE_BRANCH} and ${TEST_TARGET_BRANCH}`} | ${null}                           | ${null}
      ${`No changes between ${TEST_SOURCE_BRANCH} and version 1`}             | ${diffsMockData[0].version_index} | ${1}
      ${`No changes between version 3 and version 2`}                         | ${3}                              | ${2}
      ${`No changes between version 3 and ${TEST_TARGET_BRANCH}`}             | ${3}                              | ${-1}
    `(
      'renders text "$expectedText" (sourceIndex=$sourceIndex and targetIndex=$targetIndex)',
      ({ expectedText, targetIndex, sourceIndex }) => {
        if (targetIndex !== null) {
          store.state.diffs.startVersion = { version_index: targetIndex };
        }
        if (sourceIndex !== null) {
          store.state.diffs.mergeRequestDiff.version_index = sourceIndex;
        }

        createComponent(mount);

        expect(findMessage().text()).toBe(expectedText);
      },
    );
  });
});
