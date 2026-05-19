import { GlBadge } from '@gitlab/ui';
import Vue from 'vue';
import { PiniaVuePlugin } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { billingPlans, billingPlanNames } from '~/integrations/constants';
import DynamicField from '~/integrations/edit/components/dynamic_field.vue';
import IntegrationFormSection from '~/integrations/edit/components/integration_forms/section.vue';
import IntegrationSectionConnection from '~/integrations/edit/components/sections/connection.vue';
import IntegrationSectionJiraIssues from '~/integrations/edit/components/sections/jira_issues.vue';
import SettingsSection from '~/vue_shared/components/settings/settings_section.vue';
import { useIntegrationForm } from '~/integrations/edit/store';
import {
  mockIntegrationProps,
  mockSectionConnection,
  mockSectionJiraIssues,
} from '../../mock_data';

Vue.use(PiniaVuePlugin);

describe('Integration Form Section', () => {
  let wrapper;

  const defaultProps = {
    section: mockSectionConnection,
    isValidated: false,
  };

  const createComponent = ({
    customStateProps = {},
    props = {},
    mountFn = shallowMountExtended,
  } = {}) => {
    const pinia = createTestingPinia({ stubActions: false });
    const store = useIntegrationForm();
    Object.assign(store, {
      customState: { ...mockIntegrationProps, ...customStateProps },
    });

    wrapper = mountFn(IntegrationFormSection, {
      pinia,
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        IntegrationSectionConnection,
        IntegrationSectionJiraIssues,
        SettingsSection,
      },
    });
  };

  const findGlBadge = () => wrapper.findComponent(GlBadge);
  const findFieldsComponent = () => wrapper.findComponent(IntegrationSectionConnection);
  const findAllDynamicFields = () => wrapper.findAllComponents(DynamicField);

  beforeEach(() => {
    createComponent();
  });

  it('renders title, description and the correct dynamic component', () => {
    expect(wrapper.findByText(mockSectionConnection.title).exists()).toBe(true);
    expect(wrapper.findByText(mockSectionConnection.description).exists()).toBe(true);
    expect(findGlBadge().exists()).toBe(false);
  });

  it('renders GlBadge when `plan` is present', () => {
    createComponent({
      props: {
        section: mockSectionJiraIssues,
      },
    });

    expect(findGlBadge().exists()).toBe(true);
    expect(findGlBadge().text()).toMatchInterpolatedText(billingPlanNames[billingPlans.PREMIUM]);
  });

  it('renders only fields for this section type', () => {
    const sectionFields = [
      { name: 'username', type: 'text', section: mockSectionConnection.type },
      { name: 'API token', type: 'password', section: mockSectionConnection.type },
    ];

    const nonSectionFields = [{ name: 'branch', type: 'text' }];

    createComponent({
      customStateProps: {
        fields: [...sectionFields, ...nonSectionFields],
      },
    });

    expect(findAllDynamicFields()).toHaveLength(2);
    sectionFields.forEach((field, index) => {
      expect(findAllDynamicFields().at(index).props('name')).toBe(field.name);
    });
  });

  describe('events proxy from the section', () => {
    const dummyPayload = 'foo';

    it('toggle-integration-active', () => {
      findFieldsComponent().vm.$emit('toggle-integration-active', dummyPayload);
      expect(wrapper.emitted('toggle-integration-active')).toEqual([[dummyPayload]]);
    });

    it('request-jira-issue-types', () => {
      createComponent({
        props: { section: mockSectionJiraIssues },
      });
      wrapper
        .findComponent(IntegrationSectionJiraIssues)
        .vm.$emit('request-jira-issue-types', dummyPayload);
      expect(wrapper.emitted('request-jira-issue-types')).toEqual([[dummyPayload]]);
    });
  });
});
