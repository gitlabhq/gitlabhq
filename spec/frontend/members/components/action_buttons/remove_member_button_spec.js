import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import RemoveMemberButton from '~/members/components/action_buttons/remove_member_button.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('RemoveMemberButton', () => {
  let wrapper;

  const createStore = (state = {}) => {
    return new Vuex.Store({
      state: {
        memberPath: '/groups/foo-bar/-/group_members/:id',
        ...state,
      },
    });
  };

  const createComponent = (propsData = {}, state) => {
    wrapper = shallowMount(RemoveMemberButton, {
      localVue,
      store: createStore(state),
      propsData: {
        memberId: 1,
        message: 'Are you sure you want to remove John Smith?',
        title: 'Remove member',
        isAccessRequest: true,
        ...propsData,
      },
      directives: {
        GlTooltip: createMockDirective(),
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('sets attributes on button', () => {
    createComponent();

    expect(wrapper.attributes()).toMatchObject({
      'data-member-path': '/groups/foo-bar/-/group_members/1',
      'data-message': 'Are you sure you want to remove John Smith?',
      'data-is-access-request': 'true',
      'aria-label': 'Remove member',
      title: 'Remove member',
      icon: 'remove',
    });
  });

  it('displays `title` prop as a tooltip', () => {
    createComponent();

    expect(getBinding(wrapper.element, 'gl-tooltip')).not.toBeUndefined();
  });

  it('has CSS class used by `remove_member_modal.vue`', () => {
    createComponent();

    expect(wrapper.classes()).toContain('js-remove-member-button');
  });
});
