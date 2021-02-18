import { GlDropdown, GlDropdownItem, GlLoadingIcon, GlIcon } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import { TEST_HOST } from 'helpers/test_constants';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import EnvironmentActions from '~/environments/components/environment_actions.vue';
import eventHub from '~/environments/event_hub';

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

describe('EnvironmentActions Component', () => {
  let wrapper;

  const findEnvironmentActionsButton = () =>
    wrapper.find('[data-testid="environment-actions-button"]');

  function createComponent(props, { mountFn = shallowMount } = {}) {
    wrapper = mountFn(EnvironmentActions, {
      propsData: { actions: [], ...props },
      directives: {
        GlTooltip: createMockDirective(),
      },
    });
  }

  function createComponentWithScheduledJobs(opts = {}) {
    return createComponent({ actions: [scheduledJobAction, expiredJobAction] }, opts);
  }

  const findDropdownItem = (action) => {
    const buttons = wrapper.findAll(GlDropdownItem);
    return buttons.filter((button) => button.text().startsWith(action.name)).at(0);
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('should render a dropdown button with 2 icons', () => {
    createComponent({}, { mountFn: mount });
    expect(wrapper.find(GlDropdown).findAll(GlIcon).length).toBe(2);
  });

  it('should render a dropdown button with aria-label description', () => {
    createComponent();
    expect(wrapper.find(GlDropdown).attributes('aria-label')).toBe('Deploy to...');
  });

  it('should render a tooltip', () => {
    createComponent();
    const tooltip = getBinding(findEnvironmentActionsButton().element, 'gl-tooltip');
    expect(tooltip).toBeDefined();
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
      createComponent({ actions });
    });

    it('should render a dropdown with the provided list of actions', () => {
      expect(wrapper.findAll(GlDropdownItem)).toHaveLength(actions.length);
    });

    it("should render a disabled action when it's not playable", () => {
      const dropdownItems = wrapper.findAll(GlDropdownItem);
      const lastDropdownItem = dropdownItems.at(dropdownItems.length - 1);
      expect(lastDropdownItem.attributes('disabled')).toBe('true');
    });
  });

  describe('scheduled jobs', () => {
    let emitSpy;

    const clickAndConfirm = async ({ confirm = true } = {}) => {
      jest.spyOn(window, 'confirm').mockImplementation(() => confirm);

      findDropdownItem(scheduledJobAction).vm.$emit('click');
      await wrapper.vm.$nextTick();
    };

    beforeEach(() => {
      emitSpy = jest.fn();
      eventHub.$on('postAction', emitSpy);
      jest.spyOn(Date, 'now').mockImplementation(() => new Date('2063-04-04T00:42:00Z').getTime());
    });

    describe('when postAction event is confirmed', () => {
      beforeEach(async () => {
        createComponentWithScheduledJobs({ mountFn: mount });
        clickAndConfirm();
      });

      it('emits postAction event', () => {
        expect(window.confirm).toHaveBeenCalled();
        expect(emitSpy).toHaveBeenCalledWith({ endpoint: scheduledJobAction.playPath });
      });

      it('should render a dropdown button with a loading icon', () => {
        expect(wrapper.find(GlLoadingIcon).isVisible()).toBe(true);
      });
    });

    describe('when postAction event is denied', () => {
      beforeEach(() => {
        createComponentWithScheduledJobs({ mountFn: mount });
        clickAndConfirm({ confirm: false });
      });

      it('does not emit postAction event if confirmation is cancelled', () => {
        expect(window.confirm).toHaveBeenCalled();
        expect(emitSpy).not.toHaveBeenCalled();
      });
    });

    it('displays the remaining time in the dropdown', () => {
      createComponentWithScheduledJobs();
      expect(findDropdownItem(scheduledJobAction).text()).toContain('24:00:00');
    });

    it('displays 00:00:00 for expired jobs in the dropdown', () => {
      createComponentWithScheduledJobs();
      expect(findDropdownItem(expiredJobAction).text()).toContain('00:00:00');
    });
  });
});
