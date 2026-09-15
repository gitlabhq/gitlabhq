import { nextTick } from 'vue';
import { GlDashboardPanel, GlPopover } from '@gitlab/ui';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import ExtendedDashboardPanel from '~/vue_shared/components/customizable_dashboard/extended_dashboard_panel.vue';
import { VARIANT_DANGER, VARIANT_WARNING, VARIANT_INFO } from '~/alert';
import { stubComponent } from 'helpers/stub_component';

describe('ExtendedDashboardPanel', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  const createWrapper = ({
    props = {},
    slots = {},
    scopedSlots = {},
    mountFn = shallowMountExtended,
  } = {}) => {
    wrapper = mountFn(ExtendedDashboardPanel, {
      propsData: {
        ...props,
      },
      slots,
      scopedSlots,
      stubs: {
        GlPopover: stubComponent(GlPopover, {
          props: { ...GlPopover.props, delay: {} },
        }),
      },
    });
  };

  const findDashboardPanel = () => wrapper.findComponent(GlDashboardPanel);
  const findPanelAlertPopover = () => wrapper.findComponent(GlPopover);

  describe('default behaviour', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('sets the default props for the dashboard panel', () => {
      expect(findDashboardPanel().props()).toStrictEqual({
        containerClass: 'grid-stack-item-content',
        bodyContentClass: '',
        borderColorClass: '',
        title: '',
        titleIcon: '',
        titleIconClass: '',
        titlePopover: {},
        titlePopoverClasses: '',
        subtitle: '',
        loading: false,
        loadingDelayed: false,
        loadingDelayedText: 'Still loading…',
        actions: [],
        actionsToggleText: 'Actions',
      });
    });

    it('does not render an error popover', () => {
      expect(findPanelAlertPopover().exists()).toBe(false);
    });
  });

  describe('with a title', () => {
    beforeEach(() => {
      createWrapper({
        props: {
          title: 'Panel title',
        },
      });
    });

    it('sets the title prop', () => {
      expect(findDashboardPanel().props('title')).toBe('Panel title');
    });
  });

  describe('with a titleIcon and no alert state', () => {
    beforeEach(() => {
      createWrapper({
        props: {
          titleIcon: 'chart',
        },
      });
    });

    it('renders the titleIcon in the panel header', () => {
      expect(findDashboardPanel().props('titleIcon')).toBe('chart');
      expect(findDashboardPanel().props('titleIconClass')).toBe('');
    });
  });

  describe('with a tooltip', () => {
    beforeEach(() => {
      createWrapper({
        props: {
          tooltip: {
            description: 'This is a description',
            descriptionLink: '#',
          },
        },
      });
    });

    it('sets the titlePopover prop', () => {
      expect(findDashboardPanel().props('titlePopover')).toStrictEqual({
        description: 'This is a description',
        descriptionLink: '#',
      });
    });
  });

  describe('with actions', () => {
    beforeEach(() => {
      createWrapper({
        props: {
          actions: [
            {
              text: 'Delete',
              icon: 'remove',
            },
          ],
        },
      });
    });

    it('sets the actions prop', () => {
      expect(findDashboardPanel().props('actions')).toStrictEqual([
        {
          text: 'Delete',
          icon: 'remove',
        },
      ]);
    });
  });

  it.each(['body', 'filters'])('renders the "%s" slot', (slotName) => {
    const slotTestId = `${slotName}-slot-test-id`;

    createWrapper({
      slots: {
        [slotName]: `<div data-testid="${slotTestId}"></div>`,
      },
    });

    expect(wrapper.findByTestId(slotTestId).exists()).toBe(true);
  });

  describe('when loading', () => {
    beforeEach(() => {
      createWrapper({
        props: {
          loading: true,
        },
      });
    });

    it('sets the dashboard panel loading prop', () => {
      expect(findDashboardPanel().props('loading')).toBe(true);
    });

    it('renders the additional "Still loading" indicator if the data source is slow', async () => {
      await wrapper.setProps({ loadingDelayed: true });
      await nextTick();

      expect(findDashboardPanel().props('loadingDelayed')).toBe(true);
    });
  });

  describe('Alert variants', () => {
    describe.each`
      alertVariant       | borderColor                 | iconName           | iconColor
      ${VARIANT_DANGER}  | ${'gl-border-t-red-500'}    | ${'error'}         | ${'gl-text-danger'}
      ${VARIANT_WARNING} | ${'gl-border-t-orange-500'} | ${'warning'}       | ${'gl-text-warning'}
      ${VARIANT_INFO}    | ${'gl-border-t-blue-500'}   | ${'information-o'} | ${'gl-text-blue-500'}
    `('when the alert is $alertVariant', ({ alertVariant, borderColor, iconName, iconColor }) => {
      beforeEach(() => {
        createWrapper({
          props: {
            title: 'Panel title',
            titleIcon: 'chart',
            alertPopoverTitle: 'Some error',
            showAlertState: true,
            alertVariant,
          },
          scopedSlots: {
            'alert-popover': '<div data-testid="panel-alert-popover-slot">Alert popover</div>',
          },
          mountFn: mountExtended,
        });
      });

      it('sets the panel colors', () => {
        expect(findDashboardPanel().props('borderColorClass')).toBe(borderColor);
      });

      it('renders the alert icon, taking precedence over the titleIcon', () => {
        expect(findDashboardPanel().props('titleIcon')).toBe(iconName);
        expect(findDashboardPanel().props('titleIconClass')).toBe(iconColor);
      });

      it('renders the alert message slot', () => {
        expect(findPanelAlertPopover().props()).toMatchObject({
          title: 'Some error',
          triggers: 'hover focus',
          delay: { hide: 500 },
          showCloseButton: false,
          placement: 'top',
          cssClasses: ['gl-max-w-1/2'],
          target: expect.stringContaining('gl-dashboard-panel-id-'),
          boundary: 'viewport',
        });

        expect(findPanelAlertPopover().attributes()).toMatchObject({
          'aria-describedby': expect.stringContaining('gl-dashboard-panel-id-'),
        });
      });

      it('renders the alert popover slot', () => {
        expect(wrapper.findByTestId('panel-alert-popover-slot').exists()).toBe(true);
      });

      it.each`
        eventName            | alertPopoverShown
        ${`dropdown-open`}   | ${false}
        ${`dropdown-closed`} | ${true}
      `(
        'when the dropdown event $eventName is emitted, the alert popover is $alertPopoverShown',
        async ({ eventName, alertPopoverShown }) => {
          findDashboardPanel().vm.$emit(eventName);
          await nextTick();
          expect(findPanelAlertPopover().exists()).toBe(alertPopoverShown);
        },
      );
    });
  });

  describe('footer slot', () => {
    const findFooter = () => wrapper.findByTestId('panel-footer');
    const findBodyWrapper = () => wrapper.findByTestId('panel-body-content');

    describe('when a footer slot is provided', () => {
      beforeEach(() => {
        createWrapper({
          mountFn: mountExtended,
          slots: {
            body: '<div data-testid="panel-body-slot"></div>',
            footer: '<a data-testid="panel-footer-slot">View adoption</a>',
          },
        });
      });

      it('renders the footer slot content', () => {
        expect(wrapper.findByTestId('panel-footer-slot').exists()).toBe(true);
      });

      it('renders the body slot alongside it', () => {
        expect(wrapper.findByTestId('panel-body-slot').exists()).toBe(true);
      });

      // The visualization scrolls and the footer stays put, so the grow wrapper owns the
      // overflow and the footer must not shrink.
      it('gives the body the remaining space and keeps the footer at its own height', () => {
        expect(findBodyWrapper().classes()).toEqual(
          expect.arrayContaining(['gl-min-h-0', 'gl-grow', 'gl-overflow-y-auto']),
        );
        expect(findFooter().classes()).toContain('gl-shrink-0');
      });

      // A scrollable region has to be reachable by keyboard, or content the footer
      // pushed out of view cannot be scrolled to without a pointer.
      it('makes the scrollable body focusable', () => {
        expect(findBodyWrapper().attributes('tabindex')).toBe('0');
      });
    });

    // The footer lives inside GlDashboardPanel's body slot, so it would otherwise
    // depend on a body slot being passed too.
    describe('when only a footer slot is provided', () => {
      beforeEach(() => {
        createWrapper({
          mountFn: mountExtended,
          slots: { footer: '<a data-testid="panel-footer-slot">View adoption</a>' },
        });
      });

      it('still renders the footer', () => {
        expect(wrapper.findByTestId('panel-footer-slot').exists()).toBe(true);
      });
    });

    describe('when no footer slot is provided', () => {
      beforeEach(() => {
        createWrapper({
          mountFn: mountExtended,
          slots: { body: '<div data-testid="panel-body-slot"></div>' },
        });
      });

      it('does not render a footer', () => {
        expect(findFooter().exists()).toBe(false);
      });

      // Panels without a footer must keep GlDashboardPanel's own body layout.
      it('does not wrap the body', () => {
        expect(findBodyWrapper().exists()).toBe(false);
        expect(wrapper.findByTestId('panel-body-slot').exists()).toBe(true);
      });
    });
  });
});
