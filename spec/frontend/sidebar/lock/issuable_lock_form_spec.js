import { shallowMount } from '@vue/test-utils';
import { mockTracking, triggerEvent } from 'helpers/tracking_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import IssuableLockForm from '~/sidebar/components/lock/issuable_lock_form.vue';
import EditForm from '~/sidebar/components/lock/edit_form.vue';
import createStore from '~/notes/stores';
import { createStore as createMrStore } from '~/mr_notes/stores';
import { ISSUABLE_TYPE_ISSUE, ISSUABLE_TYPE_MR } from './constants';

describe('IssuableLockForm', () => {
  let wrapper;
  let store;
  let issuableType; // Either ISSUABLE_TYPE_ISSUE or ISSUABLE_TYPE_MR

  const setIssuableType = pageType => {
    issuableType = pageType;
  };

  const findSidebarCollapseIcon = () => wrapper.find('[data-testid="sidebar-collapse-icon"]');
  const findLockStatus = () => wrapper.find('[data-testid="lock-status"]');
  const findEditLink = () => wrapper.find('[data-testid="edit-link"]');
  const findEditForm = () => wrapper.find(EditForm);
  const findSidebarLockStatusTooltip = () =>
    getBinding(findSidebarCollapseIcon().element, 'gl-tooltip');

  const initStore = isLocked => {
    if (issuableType === ISSUABLE_TYPE_ISSUE) {
      store = createStore();
      store.getters.getNoteableData.targetType = 'issue';
    } else {
      store = createMrStore();
    }
    store.getters.getNoteableData.discussion_locked = isLocked;
  };

  const createComponent = ({ props = {} }) => {
    wrapper = shallowMount(IssuableLockForm, {
      store,
      propsData: {
        isEditable: true,
        ...props,
      },
      directives: {
        GlTooltip: createMockDirective(),
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

    describe.each`
      isLocked
      ${false} | ${true}
    `(`renders for isLocked = $isLocked`, ({ isLocked }) => {
      beforeEach(() => {
        initStore(isLocked);
        createComponent({});
      });

      it('shows the lock status', () => {
        expect(findLockStatus().text()).toBe(isLocked ? 'Locked' : 'Unlocked');
      });

      describe('edit form', () => {
        let isEditable;
        beforeEach(() => {
          isEditable = false;
          createComponent({ props: { isEditable } });
        });

        describe('when not editable', () => {
          it('does not display the edit form when opened if not editable', () => {
            expect(findEditForm().exists()).toBe(false);
            findSidebarCollapseIcon().trigger('click');

            return wrapper.vm.$nextTick().then(() => {
              expect(findEditForm().exists()).toBe(false);
            });
          });
        });

        describe('when editable', () => {
          beforeEach(() => {
            isEditable = true;
            createComponent({ props: { isEditable } });
          });

          it('shows the editable status', () => {
            expect(findEditLink().exists()).toBe(isEditable);
            expect(findEditLink().text()).toBe('Edit');
          });

          describe("when 'Edit' is clicked", () => {
            it('displays the edit form when editable', () => {
              expect(findEditForm().exists()).toBe(false);
              findEditLink().trigger('click');

              return wrapper.vm.$nextTick().then(() => {
                expect(findEditForm().exists()).toBe(true);
              });
            });

            it('tracks the event ', () => {
              const spy = mockTracking('_category_', wrapper.element, jest.spyOn);
              triggerEvent(findEditLink().element);

              expect(spy).toHaveBeenCalledWith('_category_', 'click_edit_button', {
                label: 'right_sidebar',
                property: 'lock_issue',
              });
            });
          });

          describe('When sidebar is collapsed', () => {
            it('displays the edit form when opened', () => {
              expect(findEditForm().exists()).toBe(false);
              findSidebarCollapseIcon().trigger('click');

              return wrapper.vm.$nextTick().then(() => {
                expect(findEditForm().exists()).toBe(true);
              });
            });

            it('renders a tooltip with the lock status text', () => {
              const tooltip = findSidebarLockStatusTooltip();

              expect(tooltip).toBeDefined();
              expect(tooltip.value.title).toBe(isLocked ? 'Locked' : 'Unlocked');
            });
          });
        });
      });
    });
  });
});
