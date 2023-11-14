import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import StickyHeader from '~/merge_requests/components/sticky_header.vue';

Vue.use(Vuex);

let wrapper;

function createComponent(provide = {}) {
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
    stubs: {
      GlSprintf,
    },
  });
}

describe('Merge requests sticky header component', () => {
  describe('forked project', () => {
    it('renders source branch with source project path', () => {
      createComponent({
        projectPath: 'gitlab-org/gitlab',
        sourceProjectPath: 'root/gitlab',
      });

      expect(wrapper.findByTestId('source-branch').text()).toBe('root/gitlab:source-branch');
    });
  });
});
