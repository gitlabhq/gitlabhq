import { mount, createLocalVue, createWrapper } from '@vue/test-utils';
import Vuex from 'vuex';
import {
  getByText as getByTextHelper,
  getByTestId as getByTestIdHelper,
} from '@testing-library/dom';
import MembersTable from '~/vue_shared/components/members/table/members_table.vue';
import * as initUserPopovers from '~/user_popovers';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('MemberList', () => {
  let wrapper;

  const createStore = (state = {}) => {
    return new Vuex.Store({
      state: {
        members: [],
        tableFields: [],
        ...state,
      },
    });
  };

  const createComponent = state => {
    wrapper = mount(MembersTable, {
      localVue,
      store: createStore(state),
      stubs: ['member-avatar'],
    });
  };

  const getByText = (text, options) =>
    createWrapper(getByTextHelper(wrapper.element, text, options));

  const getByTestId = (id, options) =>
    createWrapper(getByTestIdHelper(wrapper.element, id, options));

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('fields', () => {
    it.each`
      field           | label
      ${'source'}     | ${'Source'}
      ${'granted'}    | ${'Access granted'}
      ${'invited'}    | ${'Invited'}
      ${'requested'}  | ${'Requested'}
      ${'expires'}    | ${'Access expires'}
      ${'maxRole'}    | ${'Max role'}
      ${'expiration'} | ${'Expiration'}
    `('renders the $label field', ({ field, label }) => {
      createComponent({
        tableFields: [field],
      });

      expect(getByText(label, { selector: '[role="columnheader"]' }).exists()).toBe(true);
    });

    it('renders "Actions" field for screen readers', () => {
      createComponent({ tableFields: ['actions'] });

      const actionField = getByTestId('col-actions');

      expect(actionField.exists()).toBe(true);
      expect(actionField.classes('gl-sr-only')).toBe(true);
    });
  });

  describe('when `members` is an empty array', () => {
    it('displays a "No members found" message', () => {
      createComponent();

      expect(getByText('No members found').exists()).toBe(true);
    });
  });

  it('initializes user popovers when mounted', () => {
    const initUserPopoversMock = jest.spyOn(initUserPopovers, 'default');

    createComponent();

    expect(initUserPopoversMock).toHaveBeenCalled();
  });
});
