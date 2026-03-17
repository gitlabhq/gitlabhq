import { GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ReportSection, {
  SECTION_ITEM_LEVEL,
} from '~/merge_requests/reports/components/report_section.vue';
import StatusIcon from '~/vue_merge_request_widget/components/widget/status_icon.vue';
import ActionButtons from '~/vue_merge_request_widget/components/widget/action_buttons.vue';
import HelpPopover from '~/vue_shared/components/help_popover.vue';

describe('ReportSection', () => {
  let wrapper;

  const findHeaderStatusIcon = () => wrapper.findComponent(StatusIcon);
  const findActionButtons = () => wrapper.findComponent(ActionButtons);
  const findHelpPopover = () => wrapper.findComponent(HelpPopover);
  const findSummary = () => wrapper.findByTestId('summary');
  const findLoadingText = () => wrapper.findByTestId('loading-text');
  const findSections = () => wrapper.findByTestId('sections');
  const findAllSections = () => wrapper.findAllByTestId('section');
  const findAllSectionHeaders = () => wrapper.findAllByTestId('section-header');
  const findAllSectionTexts = () => wrapper.findAllByTestId('section-text');
  const findAllSectionItems = () => wrapper.findAllByTestId('section-item');

  const DEFAULT_PROPS = {
    summary: { title: 'Detected 3 new licenses' },
    actionButtons: [{ text: 'Full report', href: '/report' }],
    helpPopover: {
      options: { title: 'Help title' },
      content: {
        text: 'Help text',
        learnMorePath: '/learn-more',
      },
    },
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(ReportSection, {
      propsData: { ...DEFAULT_PROPS, ...props },
    });
  };

  describe('loading', () => {
    it('passes isLoading to status icon', () => {
      createComponent({ isLoading: true });

      expect(findHeaderStatusIcon().props('isLoading')).toBe(true);
    });

    it('shows loading text when loading', () => {
      createComponent({ isLoading: true, loadingText: 'Loading message' });

      expect(findLoadingText().text()).toBe('Loading message');
    });

    it('hides summary, help popover, and action buttons when loading', () => {
      createComponent({ isLoading: true });

      expect(findSummary().exists()).toBe(false);
      expect(findHelpPopover().exists()).toBe(false);
      expect(findActionButtons().exists()).toBe(false);
    });

    it('shows content when not loading', () => {
      createComponent();

      expect(findSummary().exists()).toBe(true);
      expect(findHelpPopover().exists()).toBe(true);
      expect(findActionButtons().exists()).toBe(true);
    });
  });

  describe('summary', () => {
    it('renders summary title', () => {
      createComponent();

      expect(findSummary().text()).toBe(DEFAULT_PROPS.summary.title);
    });

    it('does not render summary when no title provided', () => {
      createComponent({ summary: {} });

      expect(findSummary().exists()).toBe(false);
    });
  });

  describe('status icon', () => {
    it('uses provided statusIconName', () => {
      createComponent({ statusIconName: 'warning' });

      expect(findHeaderStatusIcon().props('iconName')).toBe('warning');
    });

    it('defaults to neutral', () => {
      createComponent();

      expect(findHeaderStatusIcon().props('iconName')).toBe('neutral');
    });
  });

  describe('help popover', () => {
    it('renders help popover with content', () => {
      createComponent();

      expect(findHelpPopover().exists()).toBe(true);
      expect(findHelpPopover().props('options')).toEqual(DEFAULT_PROPS.helpPopover.options);
    });

    it('does not render help popover when not provided', () => {
      createComponent({ helpPopover: null });

      expect(findHelpPopover().exists()).toBe(false);
    });

    it('adds margin when action buttons are present', () => {
      createComponent();

      expect(findHelpPopover().classes()).toContain('gl-mr-3');
    });

    it('does not add margin when no action buttons', () => {
      createComponent({ actionButtons: [] });

      expect(findHelpPopover().classes()).not.toContain('gl-mr-3');
    });
  });

  describe('action buttons', () => {
    it('renders action buttons', () => {
      createComponent();

      expect(findActionButtons().exists()).toBe(true);
      expect(findActionButtons().props('tertiaryButtons')).toEqual(DEFAULT_PROPS.actionButtons);
    });

    it('does not render action buttons when empty', () => {
      createComponent({ actionButtons: [] });

      expect(findActionButtons().exists()).toBe(false);
    });
  });

  describe('sections', () => {
    const MOCK_DENIED_SECTION = {
      header: 'Denied',
      text: 'Out-of-compliance with policies',
      children: [
        {
          icon: { name: 'failed' },
          link: { href: 'https://example.com/gpl', text: 'GPL-3.0' },
          supportingText: 'Used by lodash, webpack',
        },
      ],
    };

    const MOCK_UNCATEGORIZED_SECTION = {
      header: 'Uncategorized',
      text: 'No policy matches this license',
      children: [
        {
          icon: { name: 'notice' },
          link: { href: 'https://example.com/mit', text: 'MIT' },
          actions: [{ text: 'Used by 2 packages', href: '/full-report' }],
        },
        {
          icon: { name: 'notice' },
          link: { href: 'https://example.com/isc', text: 'ISC' },
          actions: [{ text: 'Used by 1 package', href: '/full-report' }],
        },
      ],
    };

    const MOCK_SECTIONS = [MOCK_DENIED_SECTION, MOCK_UNCATEGORIZED_SECTION];

    it('does not render sections when empty', () => {
      createComponent();

      expect(findSections().exists()).toBe(false);
    });

    it('renders correct number of sections', () => {
      createComponent({ sections: MOCK_SECTIONS });

      expect(findAllSections()).toHaveLength(2);
    });

    describe('section headers', () => {
      it('renders section headers', () => {
        createComponent({ sections: MOCK_SECTIONS });

        const headers = findAllSectionHeaders();

        expect(headers.at(0).text()).toBe(MOCK_DENIED_SECTION.header);
        expect(headers.at(1).text()).toBe(MOCK_UNCATEGORIZED_SECTION.header);
      });

      it('renders section description text', () => {
        createComponent({ sections: MOCK_SECTIONS });

        const texts = findAllSectionTexts();

        expect(texts.at(0).text()).toBe(MOCK_DENIED_SECTION.text);
        expect(texts.at(1).text()).toBe(MOCK_UNCATEGORIZED_SECTION.text);
      });

      it('does not render section text when not provided', () => {
        createComponent({ sections: [{ header: 'Denied', children: [] }] });

        expect(findAllSectionTexts()).toHaveLength(0);
      });
    });

    describe('section items', () => {
      it('renders item status icon with correct level', () => {
        createComponent({ sections: MOCK_SECTIONS });

        const itemIcons = wrapper
          .findAllComponents(StatusIcon)
          .filter((w) => w.props('name') === 'ReportItem');

        expect(itemIcons.at(0).props('level')).toBe(SECTION_ITEM_LEVEL);
        expect(itemIcons.at(0).props('iconName')).toBe(MOCK_DENIED_SECTION.children[0].icon.name);
      });

      it('renders item links', () => {
        createComponent({ sections: MOCK_SECTIONS });

        const items = findAllSectionItems();
        const firstItemLink = items.at(0).findComponent(GlLink);

        expect(firstItemLink.attributes('href')).toBe(MOCK_DENIED_SECTION.children[0].link.href);
        expect(firstItemLink.text()).toBe(MOCK_DENIED_SECTION.children[0].link.text);
      });

      it('renders item supporting text for denied licenses', () => {
        createComponent({ sections: MOCK_SECTIONS });

        const supportingText = wrapper.findByTestId('item-supporting-text');

        expect(supportingText.text()).toBe(MOCK_DENIED_SECTION.children[0].supportingText);
      });

      it('renders item action buttons for non-denied licenses', () => {
        createComponent({ sections: MOCK_SECTIONS });

        const itemActionButtons = wrapper
          .findAllComponents(ActionButtons)
          .filter((w) => w.classes('gl-ml-auto'));

        expect(itemActionButtons).toHaveLength(2);
        expect(itemActionButtons.at(0).props('tertiaryButtons')).toEqual(
          MOCK_UNCATEGORIZED_SECTION.children[0].actions,
        );
      });
    });
  });
});
