import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import BoardNewIssue from '~/boards/components/board_new_issue.vue';

import { mockList, mockGroupProjects } from '../mock_data';

const localVue = createLocalVue();

localVue.use(Vuex);

describe('Issue boards new issue form', () => {
  let wrapper;
  let vm;

  const addListNewIssuesSpy = jest.fn();

  const findSubmitButton = () => wrapper.find({ ref: 'submitButton' });
  const findCancelButton = () => wrapper.find({ ref: 'cancelButton' });
  const findSubmitForm = () => wrapper.find({ ref: 'submitForm' });

  const submitIssue = () => {
    const dummySubmitEvent = {
      preventDefault() {},
    };

    return findSubmitForm().trigger('submit', dummySubmitEvent);
  };

  beforeEach(() => {
    const store = new Vuex.Store({
      state: { selectedProject: mockGroupProjects[0] },
      actions: { addListNewIssue: addListNewIssuesSpy },
      getters: { isGroupBoard: () => false, isProjectBoard: () => true },
    });

    wrapper = shallowMount(BoardNewIssue, {
      propsData: {
        disabled: false,
        list: mockList,
      },
      store,
      localVue,
      provide: {
        groupId: null,
        weightFeatureAvailable: false,
        boardWeight: null,
      },
    });

    vm = wrapper.vm;

    return vm.$nextTick();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('calls submit if submit button is clicked', async () => {
    jest.spyOn(wrapper.vm, 'submit').mockImplementation();
    wrapper.setData({ title: 'Testing Title' });

    await vm.$nextTick();
    await submitIssue();
    expect(wrapper.vm.submit).toHaveBeenCalled();
  });

  it('disables submit button if title is empty', () => {
    expect(findSubmitButton().props().disabled).toBe(true);
  });

  it('enables submit button if title is not empty', async () => {
    wrapper.setData({ title: 'Testing Title' });

    await vm.$nextTick();
    expect(wrapper.find({ ref: 'input' }).element.value).toBe('Testing Title');
    expect(findSubmitButton().props().disabled).toBe(false);
  });

  it('clears title after clicking cancel', async () => {
    findCancelButton().trigger('click');

    await vm.$nextTick();
    expect(vm.title).toBe('');
  });

  describe('submit success', () => {
    it('creates new issue', async () => {
      wrapper.setData({ title: 'create issue' });

      await vm.$nextTick();
      await submitIssue();
      expect(addListNewIssuesSpy).toHaveBeenCalled();
    });

    it('enables button after submit', async () => {
      jest.spyOn(wrapper.vm, 'submit').mockImplementation();
      wrapper.setData({ title: 'create issue' });

      await vm.$nextTick();
      await submitIssue();
      expect(findSubmitButton().props().disabled).toBe(false);
    });

    it('clears title after submit', async () => {
      wrapper.setData({ title: 'create issue' });

      await vm.$nextTick();
      await submitIssue();
      await vm.$nextTick();
      expect(vm.title).toBe('');
    });
  });
});
