import { GlDisclosureDropdown } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import RefTrackingListItem from '~/security_configuration/components/ref_tracking_list_item.vue';
import RefTrackingMetadata from '~/security_configuration/components/ref_tracking_metadata.vue';
import { createTrackedRef } from '../mock_data';

describe('RefTrackingListItem component', () => {
  let wrapper;

  const createComponent = ({ trackedRef = createTrackedRef() } = {}) => {
    wrapper = mountExtended(RefTrackingListItem, {
      propsData: {
        trackedRef,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  const findListItem = () => wrapper.find('li');
  const findMetadataComponent = () => wrapper.findComponent(RefTrackingMetadata);
  const findVulnerabilitiesCount = () => wrapper.findByTestId('vulnerabilities-count');
  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findDropdownTooltip = () => getBinding(findDropdown().element, 'gl-tooltip');

  describe('component rendering', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders a list item', () => {
      expect(findListItem().exists()).toBe(true);
    });

    it('renders RefTrackingMetadata component', () => {
      expect(findMetadataComponent().exists()).toBe(true);
    });

    it('passes trackedRef prop to RefTrackingMetadata', () => {
      expect(findMetadataComponent().props('trackedRef')).toEqual(createTrackedRef());
    });

    it('renders GlDisclosureDropdown', () => {
      expect(findDropdown().exists()).toBe(true);
    });
  });

  describe('vulnerabilities count display', () => {
    it.each`
      count | expected
      ${1}  | ${'1 open vulnerability'}
      ${2}  | ${'2 open vulnerabilities'}
      ${0}  | ${'0 open vulnerabilities'}
    `('displays correct count for $count vulnerabilities', ({ count, expected }) => {
      createComponent({ trackedRef: createTrackedRef({ vulnerabilitiesCount: count }) });

      expect(findVulnerabilitiesCount().text()).toMatchInterpolatedText(expected);
    });
  });

  it('passes trackedRef prop to RefTrackingMetadata', () => {
    createComponent();

    expect(findMetadataComponent().props('trackedRef')).toEqual(createTrackedRef());
  });

  describe('dropdown actions', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders dropdown with correct props', () => {
      const dropdown = findDropdown();

      expect(dropdown.props()).toMatchObject({
        icon: 'ellipsis_v',
        noCaret: true,
        category: 'tertiary',
        toggleText: 'Actions',
        textSrOnly: true,
        placement: 'bottom-end',
      });
    });

    it('contains untrack action with correct properties', () => {
      const items = findDropdown().props('items');
      const untrackAction = items[0];

      expect(items).toHaveLength(1);
      expect(untrackAction).toMatchObject({
        text: 'Remove ref tracking',
        variant: 'danger',
      });
    });

    it('emits untrack event with tracked ref when untrack action is triggered', () => {
      const dropdown = findDropdown();
      const untrackAction = dropdown.props('items')[0].action;

      untrackAction();

      expect(wrapper.emitted('untrack')).toHaveLength(1);
      expect(wrapper.emitted('untrack')[0]).toEqual([createTrackedRef()]);
    });

    it('disables the dropdown when the tracked ref is the default ref', () => {
      createComponent({ trackedRef: createTrackedRef({ isDefault: true }) });

      const dropdown = findDropdown();
      expect(dropdown.props('disabled')).toBe(true);
    });

    it.each([true, false])(
      'shows a tooltip on the dropdown when the tracked ref is the default ref: $isDefault',
      ({ isDefault }) => {
        createComponent({ trackedRef: createTrackedRef({ isDefault }) });

        expect(findDropdownTooltip().value).toBe(
          isDefault ? 'The default ref cannot be removed from being tracked' : '',
        );
      },
    );
  });
});
