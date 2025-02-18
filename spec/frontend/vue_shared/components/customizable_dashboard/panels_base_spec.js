import { nextTick } from 'vue';
import { GlDashboardPanel, GlPopover } from '@gitlab/ui';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import PanelsBase from '~/vue_shared/components/customizable_dashboard/panels_base.vue';
import { VARIANT_DANGER, VARIANT_WARNING, VARIANT_INFO } from '~/alert';
import { stubComponent } from 'helpers/stub_component';

describe('PanelsBase', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  const createWrapper = ({
    props = {},
    slots = {},
    scopedSlots = {},
    mountFn = shallowMountExtended,
  } = {}) => {
    wrapper = mountFn(PanelsBase, {
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
        borderColorClass: '',
        title: '',
        titleIcon: '',
        titleIconClass: '',
        titlePopover: {},
        loading: false,
        loadingDelayed: false,
        loadingDelayedText: 'Still loading...',
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
    describe('when not editing', () => {
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

      it('does not set the actions prop', () => {
        expect(findDashboardPanel().props('actions')).toStrictEqual([]);
      });
    });

    describe('when editing', () => {
      beforeEach(() => {
        createWrapper({
          props: {
            editing: true,
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
  });

  describe('with a body slot', () => {
    beforeEach(() => {
      createWrapper({
        slots: {
          body: '<div data-testid="panel-body-slot"></div>',
        },
      });
    });

    it('renders the panel body', () => {
      expect(wrapper.findByTestId('panel-body-slot').exists()).toBe(true);
    });
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

      it('sets the alert icon', () => {
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
        eventName           | alertPopoverShown
        ${`dropdownOpen`}   | ${false}
        ${`dropdownClosed`} | ${true}
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
});
