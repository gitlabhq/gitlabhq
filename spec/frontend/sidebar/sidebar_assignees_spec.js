import { shallowMount } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';
import axios from 'axios';
import SidebarAssignees from '~/sidebar/components/assignees/sidebar_assignees.vue';
import Assigness from '~/sidebar/components/assignees/assignees.vue';
import SidebarMediator from '~/sidebar/sidebar_mediator';
import SidebarService from '~/sidebar/services/sidebar_service';
import SidebarStore from '~/sidebar/stores/sidebar_store';
import Mock from './mock_data';

describe('sidebar assignees', () => {
  let wrapper;
  let mediator;
  let axiosMock;

  const createComponent = () => {
    wrapper = shallowMount(SidebarAssignees, {
      propsData: {
        mediator,
        field: '',
      },
      // Attaching to document is required because this component emits something from the parent element :/
      attachToDocument: true,
    });
  };

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
    mediator = new SidebarMediator(Mock.mediator);

    jest.spyOn(mediator, 'saveAssignees');
    jest.spyOn(mediator, 'assignYourself');

    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;

    SidebarService.singleton = null;
    SidebarStore.singleton = null;
    SidebarMediator.singleton = null;
    axiosMock.restore();
  });

  it('calls the mediator when saves the assignees', () => {
    expect(mediator.saveAssignees).not.toHaveBeenCalled();

    wrapper.vm.saveAssignees();

    expect(mediator.saveAssignees).toHaveBeenCalled();
  });

  it('calls the mediator when "assignSelf" method is called', () => {
    expect(mediator.assignYourself).not.toHaveBeenCalled();
    expect(mediator.store.assignees.length).toBe(0);

    wrapper.vm.assignSelf();

    expect(mediator.assignYourself).toHaveBeenCalled();
    expect(mediator.store.assignees.length).toBe(1);
  });

  it('hides assignees until fetched', () => {
    expect(wrapper.find(Assigness).exists()).toBe(false);

    wrapper.vm.store.isFetching.assignees = false;

    return wrapper.vm.$nextTick(() => {
      expect(wrapper.find(Assigness).exists()).toBe(true);
    });
  });
});
