import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import StickyHeader from '~/merge_requests/components/sticky_header.vue';
import ImportedBadge from '~/vue_shared/components/imported_badge.vue';

Vue.use(Vuex);

describe('Merge requests sticky header component', () => {
  let wrapper;

  const createComponent = ({ provide = {}, props = {} } = {}) => {
    const store = new Vuex.Store({
      state: {
        page: { activeTab: 'overview' },
        notes: { notes: { doneFetchingBatchDiscussions: true } },
      },
      getters: {
        getNoteableData: () => ({
          id: 1,
          source_branch: 'source-branch',
          target_branch: 'main',
        }),
        discussionTabCounter: () => 1,
      },
    });

    wrapper = shallowMountExtended(StickyHeader, {
      store,
      provide,
      propsData: {
        tabs: [],
        ...props,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findImportedBadge = () => wrapper.findComponent(ImportedBadge);

  describe('forked project', () => {
    it('renders source branch with source project path', () => {
      createComponent({
        provide: {
          projectPath: 'gitlab-org/gitlab',
          sourceProjectPath: 'root/gitlab',
        },
      });

      expect(wrapper.findByTestId('source-branch').text()).toBe('root/gitlab:source-branch');
    });
  });

  describe('imported badge', () => {
    it('renders when merge request is imported', () => {
      createComponent({
        props: { isImported: true },
      });

      expect(findImportedBadge().props('importableType')).toBe('merge_request');
    });

    it('does not render when merge request is not imported', () => {
      createComponent({
        props: { isImported: false },
      });

      expect(findImportedBadge().exists()).toBe(false);
    });
  });
});
