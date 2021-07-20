import { mount } from '@vue/test-utils';
import createFlash from '~/flash';
import { createStore as createMrStore } from '~/mr_notes/stores';
import createStore from '~/notes/stores';
import EditFormButtons from '~/sidebar/components/lock/edit_form_buttons.vue';
import eventHub from '~/sidebar/event_hub';
import { ISSUABLE_TYPE_ISSUE, ISSUABLE_TYPE_MR } from './constants';

jest.mock('~/sidebar/event_hub', () => ({ $emit: jest.fn() }));
jest.mock('~/flash');

describe('EditFormButtons', () => {
  let wrapper;
  let store;
  let issuableType;
  let issuableDisplayName;

  const setIssuableType = (pageType) => {
    issuableType = pageType;
    issuableDisplayName = issuableType.replace(/_/g, ' ');
  };

  const findLockToggle = () => wrapper.find('[data-testid="lock-toggle"]');

  const createComponent = ({ props = {}, data = {}, resolved = true }) => {
    store = issuableType === ISSUABLE_TYPE_ISSUE ? createStore() : createMrStore();

    if (resolved) {
      jest.spyOn(store, 'dispatch').mockResolvedValue();
    } else {
      jest.spyOn(store, 'dispatch').mockRejectedValue();
    }

    wrapper = mount(EditFormButtons, {
      store,
      provide: {
        fullPath: '',
      },
      propsData: {
        isLocked: false,
        issuableDisplayName,
        ...props,
      },
      data() {
        return {
          isLoading: false,
          ...data,
        };
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe.each`
    pageType
    ${ISSUABLE_TYPE_ISSUE} | ${ISSUABLE_TYPE_MR}
  `('In $pageType page', ({ pageType }) => {
    beforeEach(() => {
      setIssuableType(pageType);
    });

    describe('when isLoading', () => {
      beforeEach(() => {
        createComponent({ data: { isLoading: true } });
      });

      it('renders "Applying" in the toggle button', () => {
        expect(findLockToggle().text()).toBe('Applying');
      });

      it('disables the toggle button', () => {
        expect(findLockToggle().attributes('disabled')).toBe('disabled');
      });

      it('sets loading on the toggle button', () => {
        expect(findLockToggle().props('loading')).toBe(true);
      });
    });

    describe.each`
      isLocked | toggleText  | statusText
      ${false} | ${'Lock'}   | ${'unlocked'}
      ${true}  | ${'Unlock'} | ${'locked'}
    `('when $statusText', ({ isLocked, toggleText }) => {
      beforeEach(() => {
        createComponent({
          props: {
            isLocked,
          },
        });
      });

      it(`toggle button displays "${toggleText}"`, () => {
        expect(findLockToggle().text()).toContain(toggleText);
      });

      describe('when toggled', () => {
        describe(`when resolved`, () => {
          beforeEach(() => {
            createComponent({
              props: {
                isLocked,
              },
              resolved: true,
            });
            findLockToggle().trigger('click');
          });

          it('dispatches the correct action', () => {
            expect(store.dispatch).toHaveBeenCalledWith('updateLockedAttribute', {
              locked: !isLocked,
              fullPath: '',
            });
          });

          it('resets loading', async () => {
            await wrapper.vm.$nextTick().then(() => {
              expect(findLockToggle().props('loading')).toBe(false);
            });
          });

          it('emits close form', () => {
            return wrapper.vm.$nextTick().then(() => {
              expect(eventHub.$emit).toHaveBeenCalledWith('closeLockForm');
            });
          });

          it('does not flash an error message', () => {
            expect(createFlash).not.toHaveBeenCalled();
          });
        });

        describe(`when not resolved`, () => {
          beforeEach(() => {
            createComponent({
              props: {
                isLocked,
              },
              resolved: false,
            });
            findLockToggle().trigger('click');
          });

          it('dispatches the correct action', () => {
            expect(store.dispatch).toHaveBeenCalledWith('updateLockedAttribute', {
              locked: !isLocked,
              fullPath: '',
            });
          });

          it('resets loading', async () => {
            await wrapper.vm.$nextTick().then(() => {
              expect(findLockToggle().props('loading')).toBe(false);
            });
          });

          it('emits close form', () => {
            return wrapper.vm.$nextTick().then(() => {
              expect(eventHub.$emit).toHaveBeenCalledWith('closeLockForm');
            });
          });

          it('calls flash with the correct message', () => {
            expect(createFlash).toHaveBeenCalledWith({
              message: `Something went wrong trying to change the locked state of this ${issuableDisplayName}`,
            });
          });
        });
      });
    });
  });
});
