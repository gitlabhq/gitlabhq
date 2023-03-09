import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import axios from 'axios';
import AxiosMockAdapter from 'axios-mock-adapter';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import SidebarReviewers from '~/sidebar/components/reviewers/sidebar_reviewers.vue';
import SidebarService from '~/sidebar/services/sidebar_service';
import SidebarMediator from '~/sidebar/sidebar_mediator';
import SidebarStore from '~/sidebar/stores/sidebar_store';
import Mock from '../../mock_data';

Vue.use(VueApollo);

describe('sidebar reviewers', () => {
  const apolloMock = createMockApollo();
  let wrapper;
  let mediator;
  let axiosMock;

  const createComponent = (props) => {
    wrapper = shallowMount(SidebarReviewers, {
      apolloProvider: apolloMock,
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

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
    mediator = new SidebarMediator(Mock.mediator);

    jest.spyOn(mediator, 'saveReviewers');
    jest.spyOn(mediator, 'addSelfReview');
  });

  afterEach(() => {
    SidebarService.singleton = null;
    SidebarStore.singleton = null;
    SidebarMediator.singleton = null;
    axiosMock.restore();
  });

  it('calls the mediator when it saves the reviewers', () => {
    createComponent();

    expect(mediator.saveReviewers).not.toHaveBeenCalled();

    wrapper.vm.saveReviewers();

    expect(mediator.saveReviewers).toHaveBeenCalled();
  });

  it('calls the mediator when "reviewBySelf" method is called', () => {
    createComponent();

    expect(mediator.addSelfReview).not.toHaveBeenCalled();
    expect(mediator.store.reviewers.length).toBe(0);

    wrapper.vm.reviewBySelf();

    expect(mediator.addSelfReview).toHaveBeenCalled();
    expect(mediator.store.reviewers.length).toBe(1);
  });
});
