import { GlDropdown, GlDropdownItem, GlLoadingIcon, GlIcon } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { TEST_HOST } from 'helpers/test_constants';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import EnvironmentActions from '~/environments/components/environment_actions.vue';
import eventHub from '~/environments/event_hub';
import actionMutation from '~/environments/graphql/mutations/action.mutation.graphql';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import createMockApollo from 'helpers/mock_apollo_helper';

jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal');

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

  function createComponent(props, { mountFn = shallowMount, options = {} } = {}) {
    wrapper = mountFn(EnvironmentActions, {
      propsData: { actions: [], ...props },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      ...options,
    });
  }

  function createComponentWithScheduledJobs(opts = {}) {
    return createComponent({ actions: [scheduledJobAction, expiredJobAction] }, opts);
  }

  const findDropdownItem = (action) => {
    const buttons = wrapper.findAllComponents(GlDropdownItem);
    return buttons.filter((button) => button.text().startsWith(action.name)).at(0);
  };

  afterEach(() => {
    wrapper.destroy();
    confirmAction.mockReset();
  });

  it('should render a dropdown button with 2 icons', () => {
    createComponent({}, { mountFn: mount });
    expect(wrapper.findComponent(GlDropdown).findAllComponents(GlIcon).length).toBe(2);
  });

  it('should render a dropdown button with aria-label description', () => {
    createComponent();
    expect(wrapper.findComponent(GlDropdown).attributes('aria-label')).toBe('Deploy to...');
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
      expect(wrapper.findAllComponents(GlDropdownItem)).toHaveLength(actions.length);
    });

    it("should render a disabled action when it's not playable", () => {
      const dropdownItems = wrapper.findAllComponents(GlDropdownItem);
      const lastDropdownItem = dropdownItems.at(dropdownItems.length - 1);
      expect(lastDropdownItem.attributes('disabled')).toBe('true');
    });
  });

  describe('scheduled jobs', () => {
    let emitSpy;

    const clickAndConfirm = async ({ confirm = true } = {}) => {
      confirmAction.mockResolvedValueOnce(confirm);

      findDropdownItem(scheduledJobAction).vm.$emit('click');
      await nextTick();
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
        expect(confirmAction).toHaveBeenCalled();
        expect(emitSpy).toHaveBeenCalledWith({ endpoint: scheduledJobAction.playPath });
      });

      it('should render a dropdown button with a loading icon', () => {
        expect(wrapper.findComponent(GlLoadingIcon).isVisible()).toBe(true);
      });
    });

    describe('when postAction event is denied', () => {
      beforeEach(async () => {
        createComponentWithScheduledJobs({ mountFn: mount });
        clickAndConfirm({ confirm: false });
      });

      it('does not emit postAction event if confirmation is cancelled', () => {
        expect(confirmAction).toHaveBeenCalled();
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

  describe('graphql', () => {
    Vue.use(VueApollo);

    const action = {
      name: 'bar',
      play_path: 'https://gitlab.com/play',
    };

    let mockApollo;

    beforeEach(() => {
      mockApollo = createMockApollo();
      createComponent(
        { actions: [action], graphql: true },
        { options: { apolloProvider: mockApollo } },
      );
    });

    it('should trigger a graphql mutation on click', () => {
      jest.spyOn(mockApollo.defaultClient, 'mutate');
      findDropdownItem(action).vm.$emit('click');
      expect(mockApollo.defaultClient.mutate).toHaveBeenCalledWith({
        mutation: actionMutation,
        variables: { action },
      });
    });
  });
});
