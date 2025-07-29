import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import { PiniaVuePlugin } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import { createMockDirective } from 'helpers/vue_mock_directive';
import IssuableLockForm from '~/sidebar/components/lock/issuable_lock_form.vue';
import toast from '~/vue_shared/plugins/global_toast';
import waitForPromises from 'helpers/wait_for_promises';
import { useNotes } from '~/notes/store/legacy_notes';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { ISSUABLE_TYPE_ISSUE } from './constants';

jest.mock('~/vue_shared/plugins/global_toast');

Vue.use(PiniaVuePlugin);

describe('IssuableLockForm', () => {
  let pinia;
  let wrapper;
  let issuableType; // Either ISSUABLE_TYPE_ISSUE or ISSUABLE_TYPE_MR

  const setIssuableType = (pageType) => {
    issuableType = pageType;
  };
  const findLockButton = () => wrapper.find('[data-testid="issuable-lock"]');

  const initStore = (isLocked) => {
    if (issuableType === ISSUABLE_TYPE_ISSUE) {
      useNotes().noteableData.targetType = 'issue';
    } else {
      useNotes().noteableData.targetType = issuableType;
    }
    useNotes().noteableData.discussion_locked = isLocked;
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(IssuableLockForm, {
      pinia,
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

  beforeEach(() => {
    pinia = createTestingPinia({ plugins: [globalAccessorPlugin] });
    useLegacyDiffs();
    useNotes().updateLockedAttribute.mockResolvedValue();
  });

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
