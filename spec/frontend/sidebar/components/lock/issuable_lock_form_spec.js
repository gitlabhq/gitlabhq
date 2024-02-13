import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { createMockDirective } from 'helpers/vue_mock_directive';
import createStore from '~/notes/stores';
import IssuableLockForm from '~/sidebar/components/lock/issuable_lock_form.vue';
import toast from '~/vue_shared/plugins/global_toast';
import waitForPromises from 'helpers/wait_for_promises';
import { ISSUABLE_TYPE_ISSUE } from './constants';

jest.mock('~/vue_shared/plugins/global_toast');

Vue.use(Vuex);

describe('IssuableLockForm', () => {
  let wrapper;
  let store;
  let issuableType; // Either ISSUABLE_TYPE_ISSUE or ISSUABLE_TYPE_MR
  let updateLockedAttribute;

  const setIssuableType = (pageType) => {
    issuableType = pageType;
  };
  const findLockButton = () => wrapper.find('[data-testid="issuable-lock"]');

  const initStore = (isLocked) => {
    if (issuableType === ISSUABLE_TYPE_ISSUE) {
      store = createStore();
      store.getters.getNoteableData.targetType = 'issue';
    } else {
      updateLockedAttribute = jest.fn().mockResolvedValue();
      store = new Vuex.Store({
        getters: {
          getNoteableData: () => ({ targetType: issuableType }),
        },
        actions: {
          updateLockedAttribute,
        },
      });
    }
    store.getters.getNoteableData.discussion_locked = isLocked;
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(IssuableLockForm, {
      store,
      provide: {
        fullPath: '',
      },
      propsData: {
        isEditable: true,
        ...props,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  describe('merge requests', () => {
    beforeEach(() => {
      setIssuableType('merge_request');
    });

    it.each`
      locked   | message
      ${true}  | ${'Discussion locked.'}
      ${false} | ${'Discussion unlocked.'}
    `('displays $message when merge request is $locked', async ({ locked, message }) => {
      initStore(locked);

      createComponent();

      await findLockButton().trigger('click');

      await waitForPromises();

      expect(toast).toHaveBeenCalledWith(message);
    });
  });
});
