import { shallowMount } from '@vue/test-utils';
import axios from 'axios';
import AxiosMockAdapter from 'axios-mock-adapter';
import Assigness from '~/sidebar/components/assignees/assignees.vue';
import AssigneesRealtime from '~/sidebar/components/assignees/assignees_realtime.vue';
import SidebarAssignees from '~/sidebar/components/assignees/sidebar_assignees.vue';
import SidebarService from '~/sidebar/services/sidebar_service';
import SidebarMediator from '~/sidebar/sidebar_mediator';
import SidebarStore from '~/sidebar/stores/sidebar_store';
import Mock from './mock_data';

describe('sidebar assignees', () => {
  let wrapper;
  let mediator;
  let axiosMock;
  const createComponent = (realTimeIssueSidebar = false, props) => {
    wrapper = shallowMount(SidebarAssignees, {
      propsData: {
        issuableIid: '1',
        issuableId: 1,
        mediator,
        field: '',
        projectPath: 'projectPath',
        changing: false,
        ...props,
      },
      provide: {
        glFeatures: {
          realTimeIssueSidebar,
        },
      },
      // Attaching to document is required because this component emits something from the parent element :/
      attachTo: document.body,
    });
  };

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
    mediator = new SidebarMediator(Mock.mediator);

    jest.spyOn(mediator, 'saveAssignees');
    jest.spyOn(mediator, 'assignYourself');
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
    createComponent();

    expect(mediator.saveAssignees).not.toHaveBeenCalled();

    wrapper.vm.saveAssignees();

    expect(mediator.saveAssignees).toHaveBeenCalled();
  });

  it('calls the mediator when "assignSelf" method is called', () => {
    createComponent();

    expect(mediator.assignYourself).not.toHaveBeenCalled();
    expect(mediator.store.assignees.length).toBe(0);

    wrapper.vm.assignSelf();

    expect(mediator.assignYourself).toHaveBeenCalled();
    expect(mediator.store.assignees.length).toBe(1);
  });

  it('hides assignees until fetched', () => {
    createComponent();

    expect(wrapper.find(Assigness).exists()).toBe(false);

    wrapper.vm.store.isFetching.assignees = false;

    return wrapper.vm.$nextTick(() => {
      expect(wrapper.find(Assigness).exists()).toBe(true);
    });
  });

  describe('when realTimeIssueSidebar is turned on', () => {
    describe('when issuableType is issue', () => {
      it('finds AssigneesRealtime componeont', () => {
        createComponent(true);

        expect(wrapper.find(AssigneesRealtime).exists()).toBe(true);
      });
    });

    describe('when issuableType is MR', () => {
      it('does not find AssigneesRealtime componeont', () => {
        createComponent(true, { issuableType: 'MR' });

        expect(wrapper.find(AssigneesRealtime).exists()).toBe(false);
      });
    });
  });

  describe('when realTimeIssueSidebar is turned off', () => {
    it('does not find AssigneesRealtime', () => {
      createComponent(false, { issuableType: 'issue' });

      expect(wrapper.find(AssigneesRealtime).exists()).toBe(false);
    });
  });
});
