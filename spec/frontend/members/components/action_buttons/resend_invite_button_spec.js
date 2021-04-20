import { GlButton } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import ResendInviteButton from '~/members/components/action_buttons/resend_invite_button.vue';
import { MEMBER_TYPES } from '~/members/constants';

jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));

const localVue = createLocalVue();
localVue.use(Vuex);

describe('ResendInviteButton', () => {
  let wrapper;

  const createStore = (state = {}) => {
    return new Vuex.Store({
      modules: {
        [MEMBER_TYPES.invite]: {
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
      localVue,
      store: createStore(state),
      provide: {
        namespace: MEMBER_TYPES.invite,
      },
      propsData: {
        memberId: 1,
        ...propsData,
      },
      directives: {
        GlTooltip: createMockDirective(),
      },
    });
  };

  const findForm = () => wrapper.find('form');
  const findButton = () => findForm().find(GlButton);

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
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
