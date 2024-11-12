import { nextTick } from 'vue';
import {
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlLoadingIcon,
  GlPopover,
  GlIcon,
  GlLink,
  GlSprintf,
} from '@gitlab/ui';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import PanelsBase from '~/vue_shared/components/customizable_dashboard/panels_base.vue';
import { VARIANT_DANGER, VARIANT_WARNING, VARIANT_INFO } from '~/alert';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';
import { PANEL_POPOVER_DELAY } from '~/vue_shared/components/customizable_dashboard/constants';

describe('PanelsBase', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  const createWrapper = ({ props = {}, slots = {}, mountFn = shallowMountExtended } = {}) => {
    wrapper = mountFn(PanelsBase, {
      propsData: {
        ...props,
      },
      slots,
      stubs: { GlSprintf },
    });
  };

  const findPanelTitle = () => wrapper.findComponent(TooltipOnTruncate);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findLoadingDelayedIndicator = () => wrapper.findByTestId('panel-loading-delayed-indicator');
  const findPanelTitleTooltipIcon = () => wrapper.findByTestId('panel-title-tooltip-icon');
  const findPanelTitleAlertIcon = () => wrapper.findByTestId('panel-title-alert-icon');
  const findPanelTitlePopover = () => wrapper.findByTestId('panel-title-popover');
  const findPanelTitlePopoverLink = () => findPanelTitlePopover().findComponent(GlLink);
  const findPanelAlertPopover = () => wrapper.findComponent(GlPopover);
  const findPanelActionsDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findDropdownItemByText = (text) =>
    findPanelActionsDropdown()
      .findAllComponents(GlDisclosureDropdownItem)
      .filter((w) => w.text() === text)
      .at(0);

  describe('default behaviour', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('does not render a title', () => {
      expect(findPanelTitle().exists()).toBe(false);
    });

    it('does not render a loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findLoadingDelayedIndicator().exists()).toBe(false);
    });

    it('does not render a disclosure dropdown', () => {
      expect(findPanelActionsDropdown().exists()).toBe(false);
    });

    it('does not render an error popover', () => {
      expect(findPanelAlertPopover().exists()).toBe(false);
    });

    it('does not render the tooltip icon', () => {
      expect(findPanelTitleTooltipIcon().exists()).toBe(false);
    });

    it('does not set an alert border color', () => {
      const alertClasses = [
        'gl-border-t-red-500',
        'gl-border-t-orange-500',
        'gl-border-t-blue-500',
      ];

      alertClasses.forEach((alertClass) => {
        expect(wrapper.attributes('class')).not.toContain(alertClass);
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

    it('renders a loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
      expect(findLoadingDelayedIndicator().exists()).toBe(false);
    });

    it('renders the additional "Still loading" indicator if the data source is slow', async () => {
      await wrapper.setProps({ loadingDelayed: true });
      await nextTick();

      expect(findLoadingIcon().exists()).toBe(true);
      expect(findLoadingDelayedIndicator().exists()).toBe(true);
    });
  });

  describe('when loading with a body slot', () => {
    beforeEach(() => {
      createWrapper({
        props: {
          loading: true,
        },
        slots: {
          body: '<div data-testid="panel-body-slot"></div>',
        },
      });
    });

    it('does not render the panel body', () => {
      expect(wrapper.findByTestId('panel-body-slot').exists()).toBe(false);
    });
  });

  describe('when there is a title', () => {
    beforeEach(() => {
      createWrapper({
        props: {
          title: 'Panel Title',
        },
      });
    });

    it('renders the panel title', () => {
      expect(findPanelTitle().text()).toBe('Panel Title');
    });
  });

  describe('when there is a title with a tooltip', () => {
    describe('with description and link', () => {
      beforeEach(() => {
        createWrapper({
          props: {
            title: 'Panel Title',
            tooltip: {
              description: 'This is just information, %{linkStart}learn more%{linkEnd}',
              descriptionLink: '/foo',
            },
          },
        });
      });

      it('renders the panel title tooltip icon with special content', () => {
        expect(findPanelTitleTooltipIcon().exists()).toBe(true);
        expect(findPanelTitlePopover().text()).toBe('This is just information, learn more');
        expect(findPanelTitlePopoverLink().attributes('href')).toBe('/foo');
      });
    });

    describe('without description link', () => {
      beforeEach(() => {
        createWrapper({
          props: {
            title: 'Panel Title',
            tooltip: {
              description: 'This is just information.',
            },
          },
        });
      });

      it('renders the panel title tooltip icon with description only', () => {
        expect(findPanelTitleTooltipIcon().exists()).toBe(true);
        expect(findPanelTitlePopoverLink().exists()).toBe(false);
        expect(findPanelTitlePopover().text()).toBe('This is just information.');
      });
    });

    describe('without description', () => {
      beforeEach(() => {
        createWrapper({
          props: {
            title: 'Panel Title',
            tooltip: {
              descriptionLink: '/foo',
            },
          },
        });
      });

      it('does not render the panel title tooltip icon', () => {
        expect(findPanelTitleTooltipIcon().exists()).toBe(false);
      });
    });
  });

  describe('when there is a title with an error alert', () => {
    beforeEach(() => {
      createWrapper({
        props: {
          title: 'Panel Title',
          showAlertState: true,
          alertVariant: VARIANT_DANGER,
        },
      });
    });

    it('renders the panel title error icon', () => {
      expect(findPanelTitleAlertIcon().exists()).toBe(true);
      expect(findPanelTitleAlertIcon().attributes('name')).toBe('error');
    });
  });

  describe('when editing and there are actions', () => {
    const actions = [
      {
        icon: 'pencil',
        text: 'Edit',
        action: () => {},
      },
    ];

    beforeEach(() => {
      createWrapper({
        props: {
          editing: true,
          actions,
        },
        mountFn: mountExtended,
      });
    });

    it('renders the panel actions dropdown', () => {
      expect(findPanelActionsDropdown().props('items')).toStrictEqual(actions);
    });

    it('renders the panel action dropdown item and icon', () => {
      const dropdownItem = findDropdownItemByText(actions[0].text);

      expect(dropdownItem.exists()).toBe(true);
      expect(dropdownItem.findComponent(GlIcon).props('name')).toBe(actions[0].icon);
    });
  });

  describe('when there is an error alert title and the alert state is true', () => {
    beforeEach(() => {
      createWrapper({
        props: {
          alertPopoverTitle: 'Some error',
          showAlertState: true,
        },
        slots: {
          'alert-popover': '<div data-testid="alert-popover-slot"></div>',
        },
      });
    });

    it('renders the error popover', () => {
      const popover = findPanelAlertPopover();
      expect(popover.exists()).toBe(true);
      expect(popover.props('title')).toBe('Some error');

      // TODO: Replace with .props() once GitLab-UI adds all supported props.
      // https://gitlab.com/gitlab-org/gitlab-ui/-/issues/428
      expect(popover.vm.$attrs.delay).toStrictEqual(PANEL_POPOVER_DELAY);
    });

    it('renders the error popover slot', () => {
      expect(wrapper.findByTestId('alert-popover-slot').exists()).toBe(true);
    });
  });

  describe('when the editing and error state are true', () => {
    beforeEach(() => {
      createWrapper({
        props: {
          showAlertState: true,
          editing: true,
        },
      });
    });

    it('hides the error popover when the dropdown is shown', async () => {
      expect(findPanelAlertPopover().exists()).toBe(true);

      await findPanelActionsDropdown().vm.$emit('shown');

      expect(findPanelAlertPopover().exists()).toBe(false);
    });
  });

  describe('Alert variants', () => {
    describe.each`
      alertVariant       | borderColor                 | iconName           | iconColor
      ${VARIANT_DANGER}  | ${'gl-border-t-red-500'}    | ${'error'}         | ${'gl-text-red-500'}
      ${VARIANT_WARNING} | ${'gl-border-t-orange-500'} | ${'warning'}       | ${'gl-text-orange-500'}
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
          slots: {
            'alert-popover': '<div data-testid="alert-popover-slot"></div>',
          },
        });
      });

      it('sets the panel colors', () => {
        ['gl-border-t-2', 'gl-border-t-solid', borderColor].forEach((cssClass) => {
          expect(wrapper.attributes('class')).toContain(cssClass);
        });
      });

      it('sets the alert icon', () => {
        expect(findPanelTitleAlertIcon().attributes('name')).toBe(iconName);
        expect(findPanelTitleAlertIcon().attributes('class')).toContain(iconColor);
      });
    });
  });
});
