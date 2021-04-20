import { GlButton, GlForm } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import ApproveAccessRequestButton from '~/members/components/action_buttons/approve_access_request_button.vue';
import { MEMBER_TYPES } from '~/members/constants';

jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));

const localVue = createLocalVue();
localVue.use(Vuex);

describe('ApproveAccessRequestButton', () => {
  let wrapper;

  const createStore = (state = {}) => {
    return new Vuex.Store({
      modules: {
        [MEMBER_TYPES.accessRequest]: {
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
    wrapper = shallowMount(ApproveAccessRequestButton, {
      localVue,
      store: createStore(state),
      provide: {
        namespace: MEMBER_TYPES.accessRequest,
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

  const findForm = () => wrapper.find(GlForm);
  const findButton = () => findForm().find(GlButton);

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('displays a tooltip', () => {
    const button = findButton();

    expect(getBinding(button.element, 'gl-tooltip')).not.toBeUndefined();
    expect(button.attributes('title')).toBe('Grant access');
  });

  it('sets `aria-label` attribute', () => {
    expect(findButton().attributes('aria-label')).toBe('Grant access');
  });

  it('submits the form when button is clicked', () => {
    expect(findButton().attributes('type')).toBe('submit');
  });

  it('displays form with correct action and inputs', () => {
    const form = findForm();

    expect(form.attributes('action')).toBe(
      '/groups/foo-bar/-/group_members/1/approve_access_request',
    );
    expect(form.find('input[name="authenticity_token"]').attributes('value')).toBe(
      'mock-csrf-token',
    );
  });
});
