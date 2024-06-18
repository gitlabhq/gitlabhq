import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import ResendInviteButton from '~/members/components/action_buttons/resend_invite_button.vue';
import { MEMBERS_TAB_TYPES } from '~/members/constants';

jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));

Vue.use(Vuex);

describe('ResendInviteButton', () => {
  let wrapper;

  const createStore = (state = {}) => {
    return new Vuex.Store({
      modules: {
        [MEMBERS_TAB_TYPES.invite]: {
          namespaced: true,
          state: {
            memberPath: '/groups/foo-bar/-/group_members/:id',
            ...state,
          },
        },
      },
    });
  };

  const createComponent = (propsData = {}, state) => {
    wrapper = shallowMount(ResendInviteButton, {
      store: createStore(state),
      provide: {
        namespace: MEMBERS_TAB_TYPES.invite,
      },
      propsData: {
        memberId: 1,
        ...propsData,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  const findForm = () => wrapper.find('form');
  const findButton = () => findForm().findComponent(GlButton);

  beforeEach(() => {
    createComponent();
  });

  it('displays a tooltip', () => {
    expect(getBinding(findButton().element, 'gl-tooltip')).not.toBeUndefined();
    expect(findButton().attributes('title')).toBe('Resend invite');
  });

  it('submits the form when button is clicked', () => {
    expect(findButton().attributes('type')).toBe('submit');
  });

  it('displays form with correct action and inputs', () => {
    expect(findForm().attributes('action')).toBe('/groups/foo-bar/-/group_members/1/resend_invite');
    expect(findForm().find('input[name="authenticity_token"]').attributes('value')).toBe(
      'mock-csrf-token',
    );
  });
});
