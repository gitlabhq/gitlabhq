import { mount, createLocalVue, createWrapper } from '@vue/test-utils';
import { GlModal, GlForm } from '@gitlab/ui';
import { nextTick } from 'vue';
import { within } from '@testing-library/dom';
import Vuex from 'vuex';
import LeaveModal from '~/members/components/modals/leave_modal.vue';
import { LEAVE_MODAL_ID } from '~/members/constants';
import { member } from '../../mock_data';

jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));

const localVue = createLocalVue();
localVue.use(Vuex);

describe('LeaveModal', () => {
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
    wrapper = mount(LeaveModal, {
      localVue,
      store: createStore(state),
      propsData: {
        member,
        ...propsData,
      },
      attrs: {
        static: true,
        visible: true,
      },
    });
  };

  const findModal = () => wrapper.find(GlModal);

  const findForm = () => findModal().find(GlForm);

  const getByText = (text, options) =>
    createWrapper(within(findModal().element).getByText(text, options));

  beforeEach(async () => {
    createComponent();
    await nextTick();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('sets modal ID', () => {
    expect(findModal().props('modalId')).toBe(LEAVE_MODAL_ID);
  });

  it('displays modal title', () => {
    expect(getByText(`Leave "${member.source.name}"`).exists()).toBe(true);
  });

  it('displays modal body', () => {
    expect(getByText(`Are you sure you want to leave "${member.source.name}"?`).exists()).toBe(
      true,
    );
  });

  it('displays form with correct action and inputs', () => {
    const form = findForm();

    expect(form.attributes('action')).toBe('/groups/foo-bar/-/group_members/leave');
    expect(form.find('input[name="_method"]').attributes('value')).toBe('delete');
    expect(form.find('input[name="authenticity_token"]').attributes('value')).toBe(
      'mock-csrf-token',
    );
  });

  it('submits the form when "Leave" button is clicked', () => {
    const submitSpy = jest.spyOn(findForm().element, 'submit');

    getByText('Leave').trigger('click');

    expect(submitSpy).toHaveBeenCalled();

    submitSpy.mockRestore();
  });
});
