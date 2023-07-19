import { shallowMount } from '@vue/test-utils';
import axios from 'axios';
import AxiosMockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import Assigness from '~/sidebar/components/assignees/assignees.vue';
import AssigneesRealtime from '~/sidebar/components/assignees/assignees_realtime.vue';
import SidebarAssignees from '~/sidebar/components/assignees/sidebar_assignees.vue';
import SidebarService from '~/sidebar/services/sidebar_service';
import SidebarMediator from '~/sidebar/sidebar_mediator';
import SidebarStore from '~/sidebar/stores/sidebar_store';
import eventHub from '~/sidebar/event_hub';
import Mock from '../../mock_data';

describe('sidebar assignees', () => {
  let wrapper;
  let mediator;
  let axiosMock;
  const createComponent = (props) => {
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
      // Attaching to document is required because this component emits something from the parent element :/
      attachTo: document.body,
    });
  };

  const findAssigness = () => wrapper.findComponent(Assigness);
  const findAssigneesRealtime = () => wrapper.findComponent(AssigneesRealtime);

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
    mediator = new SidebarMediator(Mock.mediator);

    jest.spyOn(mediator, 'saveAssignees');
    jest.spyOn(mediator, 'assignYourself');
  });

  afterEach(() => {
    SidebarService.singleton = null;
    SidebarStore.singleton = null;
    SidebarMediator.singleton = null;
    axiosMock.restore();
  });

  it('calls the mediator when saves the assignees', () => {
    createComponent();

    expect(mediator.saveAssignees).not.toHaveBeenCalled();

    eventHub.$emit('sidebar.saveAssignees');

    expect(mediator.saveAssignees).toHaveBeenCalled();
  });

  it('calls the mediator when "assignSelf" method is called', async () => {
    createComponent();
    mediator.store.isFetching.assignees = false;
    await nextTick();

    expect(mediator.assignYourself).not.toHaveBeenCalled();
    expect(mediator.store.assignees.length).toBe(0);

    await findAssigness().vm.$emit('assign-self');

    expect(mediator.assignYourself).toHaveBeenCalled();
    expect(mediator.store.assignees.length).toBe(1);
  });

  it('hides assignees until fetched', async () => {
    createComponent();

    expect(findAssigness().exists()).toBe(false);

    mediator.store.isFetching.assignees = false;

    await nextTick();
    expect(findAssigness().exists()).toBe(true);
  });

  describe('when issuableType is issue', () => {
    it('finds AssigneesRealtime component', () => {
      createComponent();

      expect(findAssigneesRealtime().exists()).toBe(true);
    });
  });

  describe('when issuableType is MR', () => {
    it('does not find AssigneesRealtime component', () => {
      createComponent({ issuableType: 'MR' });

      expect(findAssigneesRealtime().exists()).toBe(false);
    });
  });
});
