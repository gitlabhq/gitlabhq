import { GlFormGroup, GlCollapsibleListbox, GlIcon } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import IssueTypeField, { i18n } from '~/issues/show/components/fields/type.vue';
import { issuableTypes } from '~/issues/show/constants';
import {
  getIssueStateQueryResponse,
  updateIssueStateQueryResponse,
} from '../../mock_data/apollo_mock';

Vue.use(VueApollo);

describe('Issue type field component', () => {
  let wrapper;
  let fakeApollo;
  let mockIssueStateData;

  const mockResolvers = {
    Query: {
      issueState() {
        return {
          __typename: 'IssueState',
          rawData: mockIssueStateData(),
        };
      },
    },
    Mutation: {
      updateIssueState: jest.fn().mockResolvedValue(updateIssueStateQueryResponse),
    },
  };

  const findListBox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findFormGroup = () => wrapper.findComponent(GlFormGroup);
  const findAllIssueItems = () => wrapper.findAll('[data-testid="issue-type-list-item"]');
  const findIssueItemAt = (at) => findAllIssueItems().at(at);
  const findIssueItemAtIcon = (at) => findAllIssueItems().at(at).findComponent(GlIcon);

  const createComponent = (mountFn = mount, { data } = {}, provide) => {
    fakeApollo = createMockApollo([], mockResolvers);

    wrapper = mountFn(IssueTypeField, {
      apolloProvider: fakeApollo,
      data() {
        return {
          issueState: {},
          ...data,
        };
      },
      provide: {
        canCreateIncident: true,
        ...provide,
      },
    });
  };

  beforeEach(() => {
    mockIssueStateData = jest.fn();
  });

  it.each`
    at   | text                     | icon
    ${0} | ${issuableTypes[0].text} | ${issuableTypes[0].icon}
    ${1} | ${issuableTypes[1].text} | ${issuableTypes[1].icon}
  `(`renders the issue type $text with an icon in the dropdown`, ({ at, text, icon }) => {
    createComponent();

    expect(findIssueItemAtIcon(at).props('name')).toBe(icon);
    expect(findIssueItemAt(at).text()).toBe(text);
  });

  it('renders a form group with the correct label', () => {
    createComponent(shallowMount);

    expect(findFormGroup().attributes('label')).toBe(i18n.label);
  });

  it('renders a form select with the `issue_type` value', () => {
    createComponent();

    expect(findListBox().attributes('value')).toBe(issuableTypes.issue);
  });

  describe('with Apollo cache mock', () => {
    it('renders the selected issueType', async () => {
      createComponent();

      mockIssueStateData.mockResolvedValue(getIssueStateQueryResponse);
      await waitForPromises();
      expect(findListBox().attributes('value')).toBe(issuableTypes.issue);
    });

    it('updates the `issue_type` in the apollo cache when the value is changed', async () => {
      createComponent();

      wrapper.vm.$emit('select', issuableTypes.incident);
      await nextTick();
      expect(findListBox().attributes('value')).toBe(issuableTypes.incident);
    });

    describe('when user is a guest', () => {
      it('hides the incident type from the dropdown', async () => {
        createComponent(mount, {}, { canCreateIncident: false, issueType: 'issue' });

        await waitForPromises();

        expect(findIssueItemAt(0).isVisible()).toBe(true);
        expect(findIssueItemAt(1).isVisible()).toBe(false);
        expect(findListBox().attributes('value')).toBe(issuableTypes.issue);
      });

      it('and incident is selected, includes incident in the dropdown', async () => {
        createComponent(mount, {}, { canCreateIncident: false, issueType: 'incident' });

        await waitForPromises();

        expect(findIssueItemAt(0).isVisible()).toBe(true);
        expect(findIssueItemAt(1).isVisible()).toBe(true);
        expect(findListBox().attributes('value')).toBe(issuableTypes.incident);
      });
    });
  });
});
