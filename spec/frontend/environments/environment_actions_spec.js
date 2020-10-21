import { shallowMount } from '@vue/test-utils';
import { TEST_HOST } from 'helpers/test_constants';
import { GlLoadingIcon, GlIcon } from '@gitlab/ui';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import eventHub from '~/environments/event_hub';
import EnvironmentActions from '~/environments/components/environment_actions.vue';

describe('EnvironmentActions Component', () => {
  let vm;

  const findEnvironmentActionsButton = () => vm.find('[data-testid="environment-actions-button"]');

  beforeEach(() => {
    vm = shallowMount(EnvironmentActions, {
      propsData: { actions: [] },
      directives: {
        GlTooltip: createMockDirective(),
      },
    });
  });

  afterEach(() => {
    vm.destroy();
  });

  it('should render a dropdown button with 2 icons', () => {
    expect(vm.find('.dropdown-new').findAll(GlIcon).length).toBe(2);
  });

  it('should render a dropdown button with aria-label description', () => {
    expect(vm.find('.dropdown-new').attributes('aria-label')).toEqual('Deploy to...');
  });

  it('should render a tooltip', () => {
    const tooltip = getBinding(findEnvironmentActionsButton().element, 'gl-tooltip');
    expect(tooltip).toBeDefined();
  });

  describe('is loading', () => {
    beforeEach(() => {
      vm.setData({ isLoading: true });
    });

    it('should render a dropdown button with a loading icon', () => {
      expect(vm.findAll(GlLoadingIcon).length).toBe(1);
    });
  });

  describe('manual actions', () => {
    const actions = [
      {
        name: 'bar',
        play_path: 'https://gitlab.com/play',
      },
      {
        name: 'foo',
        play_path: '#',
      },
      {
        name: 'foo bar',
        play_path: 'url',
        playable: false,
      },
    ];

    beforeEach(() => {
      vm.setProps({ actions });
    });

    it('should render a dropdown with the provided list of actions', () => {
      expect(vm.findAll('.dropdown-menu li').length).toEqual(actions.length);
    });

    it("should render a disabled action when it's not playable", () => {
      expect(vm.find('.dropdown-menu li:last-child gl-button-stub').props('disabled')).toBe(true);
    });
  });

  describe('scheduled jobs', () => {
    const scheduledJobAction = {
      name: 'scheduled action',
      playPath: `${TEST_HOST}/scheduled/job/action`,
      playable: true,
      scheduledAt: '2063-04-05T00:42:00Z',
    };
    const expiredJobAction = {
      name: 'expired action',
      playPath: `${TEST_HOST}/expired/job/action`,
      playable: true,
      scheduledAt: '2018-10-05T08:23:00Z',
    };
    const findDropdownItem = action => {
      const buttons = vm.findAll('.dropdown-menu li gl-button-stub');
      return buttons.filter(button => button.text().startsWith(action.name)).at(0);
    };

    beforeEach(() => {
      jest.spyOn(Date, 'now').mockImplementation(() => new Date('2063-04-04T00:42:00Z').getTime());
      vm.setProps({ actions: [scheduledJobAction, expiredJobAction] });
    });

    it('emits postAction event after confirming', () => {
      const emitSpy = jest.fn();
      eventHub.$on('postAction', emitSpy);
      jest.spyOn(window, 'confirm').mockImplementation(() => true);

      findDropdownItem(scheduledJobAction).vm.$emit('click');

      expect(window.confirm).toHaveBeenCalled();
      expect(emitSpy).toHaveBeenCalledWith({ endpoint: scheduledJobAction.playPath });
    });

    it('does not emit postAction event if confirmation is cancelled', () => {
      const emitSpy = jest.fn();
      eventHub.$on('postAction', emitSpy);
      jest.spyOn(window, 'confirm').mockImplementation(() => false);

      findDropdownItem(scheduledJobAction).vm.$emit('click');

      expect(window.confirm).toHaveBeenCalled();
      expect(emitSpy).not.toHaveBeenCalled();
    });

    it('displays the remaining time in the dropdown', () => {
      expect(findDropdownItem(scheduledJobAction).text()).toContain('24:00:00');
    });

    it('displays 00:00:00 for expired jobs in the dropdown', () => {
      expect(findDropdownItem(expiredJobAction).text()).toContain('00:00:00');
    });
  });
});
