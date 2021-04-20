import { GlButton } from '@gitlab/ui';
import { mount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import RemoveGroupLinkButton from '~/members/components/action_buttons/remove_group_link_button.vue';
import { MEMBER_TYPES } from '~/members/constants';
import { group } from '../../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('RemoveGroupLinkButton', () => {
  let wrapper;

  const actions = {
    showRemoveGroupLinkModal: jest.fn(),
  };

  const createStore = () => {
    return new Vuex.Store({
      modules: {
        [MEMBER_TYPES.group]: {
          namespaced: true,
          actions,
        },
      },
    });
  };

  const createComponent = () => {
    wrapper = mount(RemoveGroupLinkButton, {
      localVue,
      store: createStore(),
      provide: {
        namespace: MEMBER_TYPES.group,
      },
      propsData: {
        groupLink: group,
      },
      directives: {
        GlTooltip: createMockDirective(),
      },
    });
  };

  const findButton = () => wrapper.find(GlButton);

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('displays a tooltip', () => {
    const button = findButton();

    expect(getBinding(button.element, 'gl-tooltip')).not.toBeUndefined();
    expect(button.attributes('title')).toBe('Remove group');
  });

  it('sets `aria-label` attribute', () => {
    expect(findButton().attributes('aria-label')).toBe('Remove group');
  });

  it('calls Vuex action to open remove group link modal when clicked', () => {
    findButton().trigger('click');

    expect(actions.showRemoveGroupLinkModal).toHaveBeenCalledWith(expect.any(Object), group);
  });
});
