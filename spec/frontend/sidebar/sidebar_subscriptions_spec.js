import { shallowMount } from '@vue/test-utils';
import SidebarSubscriptions from '~/sidebar/components/subscriptions/sidebar_subscriptions.vue';
import SidebarMediator from '~/sidebar/sidebar_mediator';
import SidebarService from '~/sidebar/services/sidebar_service';
import SidebarStore from '~/sidebar/stores/sidebar_store';
import Mock from './mock_data';

describe('Sidebar Subscriptions', () => {
  let wrapper;
  let mediator;

  beforeEach(() => {
    mediator = new SidebarMediator(Mock.mediator);
    wrapper = shallowMount(SidebarSubscriptions, {
      propsData: {
        mediator,
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
    SidebarService.singleton = null;
    SidebarStore.singleton = null;
    SidebarMediator.singleton = null;
  });

  it('calls the mediator toggleSubscription on event', () => {
    const spy = jest.spyOn(mediator, 'toggleSubscription').mockReturnValue(Promise.resolve());

    wrapper.vm.onToggleSubscription();

    expect(spy).toHaveBeenCalled();
    spy.mockRestore();
  });
});
