import { GlButton } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import RemoveGroupLinkButton from '~/members/components/action_buttons/remove_group_link_button.vue';
import { MEMBERS_TAB_TYPES } from '~/members/constants';
import { group } from '../../mock_data';

Vue.use(Vuex);

describe('RemoveGroupLinkButton', () => {
  let wrapper;

  const actions = {
    showRemoveGroupLinkModal: jest.fn(),
  };

  const createStore = () => {
    return new Vuex.Store({
      modules: {
        [MEMBERS_TAB_TYPES.group]: {
          namespaced: true,
          actions,
        },
      },
    });
  };

  const createComponent = () => {
    wrapper = mount(RemoveGroupLinkButton, {
      store: createStore(),
      provide: {
        namespace: MEMBERS_TAB_TYPES.group,
      },
      propsData: {
        groupLink: group,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  const findButton = () => wrapper.findComponent(GlButton);

  beforeEach(() => {
    createComponent();
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
