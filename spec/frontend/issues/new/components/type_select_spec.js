import { GlCollapsibleListbox, GlIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import * as urlUtility from '~/lib/utils/url_utility';
import TypeSelect from '~/issues/new/components/type_select.vue';
import { TYPE_ISSUE, TYPE_INCIDENT } from '~/issues/constants';

const issuePath = 'issues/new';
const incidentPath = 'issues/new?issuable_template=incident';
const tracking = {
  action: 'select_issue_type_incident',
  label: 'select_issue_type_incident_dropdown_option',
};

const defaultProps = {
  selectedType: '',
  isIssueAllowed: true,
  isIncidentAllowed: true,
  issuePath,
  incidentPath,
};

const issue = {
  value: TYPE_ISSUE,
  text: 'Issue',
  icon: 'issue-type-issue',
  href: issuePath,
};
const incident = {
  value: TYPE_INCIDENT,
  text: 'Incident',
  icon: 'issue-type-incident',
  href: incidentPath,
  tracking,
};

describe('Issue type select component', () => {
  let wrapper;
  let trackingSpy;
  let navigationSpy;

  const createComponent = (props = {}) => {
    wrapper = mount(TypeSelect, {
      propsData: { ...defaultProps, ...props },
    });
  };

  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findAllIcons = () => wrapper.findAllComponents(GlIcon);
  const findListboxItemIcon = () => findAllIcons().at(2);

  describe('initial state', () => {
    it('renders listbox with the correct header text', () => {
      createComponent();

      expect(findListbox().props('headerText')).toBe(TypeSelect.i18n.selectType);
    });

    it.each`
      selectedType     | toggleText
      ${''}            | ${TypeSelect.i18n.selectType}
      ${TYPE_ISSUE}    | ${TypeSelect.i18n.issuableType[TYPE_ISSUE]}
      ${TYPE_INCIDENT} | ${TypeSelect.i18n.issuableType[TYPE_INCIDENT]}
    `(
      'renders listbox with the correct toggle text when selectedType is "$selectedType"',
      ({ selectedType, toggleText }) => {
        createComponent({ selectedType });

        expect(findListbox().props('toggleText')).toBe(toggleText);
      },
    );

    it.each`
      isIssueAllowed | isIncidentAllowed | items
      ${true}        | ${true}           | ${[issue, incident]}
      ${true}        | ${false}          | ${[issue]}
      ${false}       | ${true}           | ${[incident]}
    `(
      'renders listbox with the correct items when isIssueAllowed is "$isIssueAllowed" and isIncidentAllowed is "$isIncidentAllowed"',
      ({ isIssueAllowed, isIncidentAllowed, items }) => {
        createComponent({ isIssueAllowed, isIncidentAllowed });

        expect(findListbox().props('items')).toMatchObject(items);
      },
    );

    it.each`
      isIssueAllowed | isIncidentAllowed | icon
      ${true}        | ${false}          | ${issue.icon}
      ${false}       | ${true}           | ${incident.icon}
    `(
      'renders listbox item with the correct $icon icon',
      ({ isIssueAllowed, isIncidentAllowed, icon }) => {
        createComponent({ isIssueAllowed, isIncidentAllowed });
        findListbox().vm.$emit('shown');

        expect(findListboxItemIcon().props('name')).toBe(icon);
      },
    );
  });

  describe('on type selected', () => {
    beforeEach(() => {
      navigationSpy = jest.spyOn(urlUtility, 'visitUrl').mockReturnValue({});
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });

    afterEach(() => {
      unmockTracking();
      navigationSpy.mockRestore();
    });

    it.each`
      selectedType     | expectedUrl
      ${TYPE_ISSUE}    | ${issuePath}
      ${TYPE_INCIDENT} | ${incidentPath}
    `('navigates to the $selectedType issuable page', ({ selectedType, expectedUrl }) => {
      createComponent();
      findListbox().vm.$emit('select', selectedType);

      expect(navigationSpy).toHaveBeenCalledWith(expectedUrl);
    });

    it("doesn't call tracking APIs when tracking is not available for the issuable type", () => {
      createComponent();
      findListbox().vm.$emit('select', TYPE_ISSUE);

      expect(trackingSpy).not.toHaveBeenCalled();
    });

    it('calls tracking APIs when tracking is available for the issuable type', () => {
      createComponent();
      findListbox().vm.$emit('select', TYPE_INCIDENT);

      expect(trackingSpy).toHaveBeenCalledWith(undefined, tracking.action, {
        label: tracking.label,
      });
    });
  });
});
