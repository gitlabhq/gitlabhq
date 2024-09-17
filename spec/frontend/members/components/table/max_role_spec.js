import { GlCollapsibleListbox, GlListboxItem } from '@gitlab/ui';
import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import waitForPromises from 'helpers/wait_for_promises';
import MaxRole from '~/members/components/table/max_role.vue';
import { MEMBERS_TAB_TYPES } from '~/members/constants';
import { guestOverageConfirmAction } from 'ee_else_ce/members/guest_overage_confirm_action';
import { logError } from '~/lib/logger';
import * as utils from 'ee_else_ce/members/utils';
import { member } from '../../mock_data';

Vue.use(Vuex);

jest.mock('ee_else_ce/members/guest_overage_confirm_action');
jest.mock('~/sentry/sentry_browser_wrapper');
jest.mock('~/lib/logger');

guestOverageConfirmAction.mockReturnValue(true);

describe('MaxRole', () => {
  /** @type {import('@vue/test-utils').Wrapper} */
  let wrapper;
  let actions;
  const $toast = {
    show: jest.fn(),
  };

  const createStore = ({ updateMemberRoleReturn = Promise.resolve({ data: {} }) } = {}) => {
    actions = {
      updateMemberRole: jest.fn(() => updateMemberRoleReturn),
    };

    return new Vuex.Store({
      modules: {
        [MEMBERS_TAB_TYPES.user]: { namespaced: true, actions },
      },
    });
  };

  const createComponent = (propsData = {}, store = createStore()) => {
    wrapper = mount(MaxRole, {
      provide: {
        namespace: MEMBERS_TAB_TYPES.user,
        group: {
          name: 'groupname',
          path: '/grouppath/',
        },
      },
      propsData: {
        member,
        permissions: {
          canUpdate: true,
        },
        ...propsData,
      },
      store,
      mocks: {
        $toast,
      },
    });
  };

  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findListboxItems = () => wrapper.findAllComponents(GlListboxItem);
  const findListboxItemByText = (text) =>
    findListboxItems().wrappers.find((item) => item.text() === text);

  beforeEach(() => {
    gon.features = { showOverageOnRolePromotion: true };
  });

  describe('when member can not be updated', () => {
    it('renders the role name instead of a collapsible listbox', () => {
      createComponent({
        permissions: {
          canUpdate: false,
        },
      });

      expect(wrapper.text()).toContain('Owner');
    });
  });

  it('has correct header text props', () => {
    createComponent();
    expect(findListbox().props('headerText')).toBe('Change role');
  });

  it('has items prop with all valid roles', () => {
    createComponent();
    const roles = findListboxItems().wrappers.map((item) => item.text());
    expect(roles).toEqual(Object.keys(member.validRoles));
  });

  describe('when listbox is open', () => {
    beforeEach(async () => {
      createComponent();

      await findListbox().vm.$emit('click');
    });

    it('sets dropdown toggle and checks selected role', () => {
      expect(findListbox().find('[aria-selected=true]').text()).toBe('Owner');
    });

    describe('when dropdown item is selected', () => {
      it('does nothing if the item selected was already selected', async () => {
        await findListboxItemByText('Owner').trigger('click');

        expect(actions.updateMemberRole).not.toHaveBeenCalled();
      });

      it('calls `updateMemberRole` Vuex action', async () => {
        await findListboxItemByText('Developer').trigger('click');

        expect(actions.updateMemberRole).toHaveBeenCalledWith(expect.any(Object), {
          memberId: member.id,
          accessLevel: 30,
        });
      });

      it('puts dropdown in loading state while waiting for `updateMemberRole` to resolve', async () => {
        await findListboxItemByText('Developer').trigger('click');

        expect(findListbox().props('loading')).toBe(true);
      });

      describe('when updateMemberRole is successful', () => {
        it('calls update handler', async () => {
          jest.spyOn(utils, 'handleMemberRoleUpdate');
          await findListboxItemByText('Developer').trigger('click');

          await waitForPromises();
          expect(utils.handleMemberRoleUpdate).toHaveBeenCalledTimes(1);
        });

        it('puts dropdown in loading state while waiting for `updateMemberRole` to resolve', async () => {
          await findListboxItemByText('Developer').trigger('click');

          expect(findListbox().props('loading')).toBe(true);
        });

        it('enables dropdown after `updateMemberRole` resolves', async () => {
          await findListboxItemByText('Developer').trigger('click');

          await waitForPromises();

          expect(findListbox().props('disabled')).toBe(false);
        });

        it('does not log error to Sentry', async () => {
          await findListboxItemByText('Developer').trigger('click');

          await waitForPromises();

          expect(Sentry.captureException).not.toHaveBeenCalled();
        });
      });

      describe('when updateMemberRole is not successful', () => {
        const reason = 'Rejected ☹️';

        beforeEach(async () => {
          createComponent({}, createStore({ updateMemberRoleReturn: Promise.reject(reason) }));

          await findListboxItemByText('Developer').trigger('click');
          await waitForPromises();
        });

        it('does not display toast', () => {
          expect($toast.show).not.toHaveBeenCalled();
        });

        it('enables dropdown after `updateMemberRole` resolves', () => {
          expect(findListbox().props('disabled')).toBe(false);
        });

        it('logs error to console', () => {
          expect(logError).toHaveBeenCalledWith(reason);
        });

        it('logs error to Sentry', () => {
          expect(Sentry.captureException).toHaveBeenCalledWith(reason);
        });
      });
    });
  });

  it('sets the dropdown alignment to right on mobile', async () => {
    jest.spyOn(bp, 'isDesktop').mockReturnValue(false);
    createComponent();

    await nextTick();

    expect(findListbox().props('placement')).toBe('bottom-end');
  });

  it('sets the dropdown alignment to left on desktop', async () => {
    jest.spyOn(bp, 'isDesktop').mockReturnValue(true);
    createComponent();

    await nextTick();

    expect(findListbox().props('placement')).toBe('bottom-start');
  });
});
