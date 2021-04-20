import { GlModal, GlForm } from '@gitlab/ui';
import { within } from '@testing-library/dom';
import { mount, createLocalVue, createWrapper } from '@vue/test-utils';
import { cloneDeep } from 'lodash';
import { nextTick } from 'vue';
import Vuex from 'vuex';
import LeaveModal from '~/members/components/modals/leave_modal.vue';
import { LEAVE_MODAL_ID, MEMBER_TYPES } from '~/members/constants';
import OncallSchedulesList from '~/vue_shared/components/oncall_schedules_list.vue';
import { member } from '../../mock_data';

jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));

const localVue = createLocalVue();
localVue.use(Vuex);

describe('LeaveModal', () => {
  let wrapper;

  const createStore = (state = {}) => {
    return new Vuex.Store({
      modules: {
        [MEMBER_TYPES.user]: {
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
    wrapper = mount(LeaveModal, {
      localVue,
      store: createStore(state),
      provide: {
        namespace: MEMBER_TYPES.user,
      },
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

  const findModal = () => wrapper.findComponent(GlModal);
  const findForm = () => findModal().findComponent(GlForm);
  const findOncallSchedulesList = () => findModal().findComponent(OncallSchedulesList);

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
    expect(getByText(`Leave "${member.source.fullName}"`).exists()).toBe(true);
  });

  it('displays modal body', () => {
    expect(getByText(`Are you sure you want to leave "${member.source.fullName}"?`).exists()).toBe(
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

  describe('On-call schedules list', () => {
    it("displays oncall schedules list when member's user is part of on-call schedules ", () => {
      const schedulesList = findOncallSchedulesList();
      expect(schedulesList.exists()).toBe(true);
      expect(schedulesList.props()).toMatchObject({
        isCurrentUser: true,
        schedules: member.user.oncallSchedules,
      });
    });

    it("does NOT display oncall schedules list when member's user is NOT a part of on-call schedules ", () => {
      const memberWithoutOncallSchedules = cloneDeep(member);
      delete (memberWithoutOncallSchedules, 'user.oncallSchedules');
      createComponent({ member: memberWithoutOncallSchedules });
      expect(findOncallSchedulesList().exists()).toBe(false);
    });
  });

  it('submits the form when "Leave" button is clicked', () => {
    const submitSpy = jest.spyOn(findForm().element, 'submit');

    getByText('Leave').trigger('click');

    expect(submitSpy).toHaveBeenCalled();

    submitSpy.mockRestore();
  });
});
